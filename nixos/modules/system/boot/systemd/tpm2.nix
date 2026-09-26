{
  lib,
  config,
  pkgs,
  ...
}:
{
  meta.maintainers = [ lib.maintainers.elvishjerricco ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "boot" "initrd" "systemd" "enableTpm2" ]
      [ "boot" "initrd" "systemd" "tpm2" "enable" ]
    )
  ];

  options = {
    systemd.tpm2.enable = lib.mkEnableOption "systemd TPM2 support" // {
      default = config.systemd.package.withTpm2Units;
      defaultText = "systemd.package.withTpm2Units";
    };

    systemd.tpm2.pcrphases.enable = lib.mkEnableOption "systemd boot phase measurements";
    systemd.tpm2.softwareFallback.enable = lib.mkEnableOption ''
      a software TPM as a fallback when no TPM2 device is available. The
      software TPM stores its state in the EFI System Partition, and is only
      used when booted with EFI. See
      {manpage}`systemd-tpm2-swtpm.service(8)`
    '';

    boot.initrd.systemd.tpm2.enable = lib.mkEnableOption "systemd initrd TPM2 support" // {
      default = config.boot.initrd.systemd.package.withTpm2Units;
      defaultText = "boot.initrd.systemd.package.withTpm2Units";
    };

    boot.initrd.systemd.tpm2.pcrphases.enable =
      lib.mkEnableOption "systemd initrd boot phase measurements";
  };

  # TODO: pcrextend, pcrfs, pcrmachine
  config = lib.mkMerge [
    # Stage 2
    (
      let
        cfg = config.systemd;
      in
      lib.mkIf cfg.tpm2.enable {
        systemd.additionalUpstreamSystemUnits = [
          "tpm2.target"
          "systemd-tpm2-setup-early.service"
          "systemd-tpm2-setup.service"
          "systemd-pcrextend.socket"
          "systemd-pcrextend@.service"
          "systemd-pcrlogin@.service"
        ];
      }
    )
    (
      let
        cfg = config.systemd;
      in
      lib.mkIf (cfg.tpm2.enable && cfg.tpm2.softwareFallback.enable) {
        systemd.additionalUpstreamSystemUnits = [ "systemd-tpm2-swtpm.service" ];
        # systemd-tpm2-generator only pulls in the software TPM when requested
        # on the kernel command line and swtpm is available.
        boot.kernelParams = [ "systemd.tpm2_software_fallback=1" ];
        systemd.generatorPath = [ pkgs.swtpm ];
        systemd.services.systemd-tpm2-swtpm = {
          path = [ pkgs.swtpm ];
          serviceConfig.ExecSearchPath = lib.makeBinPath [ pkgs.swtpm ];
        };
      }
    )
    (
      let
        cfg = config.systemd;
      in
      lib.mkIf (cfg.tpm2.enable && cfg.tpm2.pcrphases.enable) {
        systemd.additionalUpstreamSystemUnits = [
          "systemd-pcrphase.service"
          "systemd-pcrphase-sysinit.service"
        ];
        systemd.services.systemd-pcrphase.wantedBy = [ "sysinit.target" ];
        systemd.services.systemd-pcrphase-sysinit.wantedBy = [ "sysinit.target" ];
      }
    )

    # Stage 1
    (
      let
        cfg = config.boot.initrd.systemd;
      in
      lib.mkIf (cfg.enable && cfg.tpm2.enable) {
        boot.initrd.systemd.additionalUpstreamUnits = [
          "tpm2.target"
          "systemd-tpm2-setup-early.service"
          "systemd-pcrextend.socket"
          "systemd-pcrextend@.service"
        ];

        boot.initrd.availableKernelModules = [
          "tpm-tis"
        ]
        ++ lib.optional (
          !(pkgs.stdenv.hostPlatform.isRiscV64 || pkgs.stdenv.hostPlatform.isArmv7)
        ) "tpm-crb";
        boot.initrd.systemd.storePaths = [
          pkgs.tpm2-tss
          "${cfg.package}/lib/systemd/systemd-tpm2-setup"
          "${cfg.package}/lib/systemd/system-generators/systemd-tpm2-generator"
          "${cfg.package}/lib/systemd/systemd-pcrextend"
        ];
      }
    )
    (
      let
        cfg = config.boot.initrd.systemd;
      in
      lib.mkIf (cfg.enable && cfg.tpm2.enable && cfg.tpm2.pcrphases.enable) {
        boot.initrd.systemd.additionalUpstreamUnits = [
          "systemd-pcrphase-initrd.service"
          "systemd-pcrosseparator.service"
        ];
        boot.initrd.systemd.services.systemd-pcrphase-initrd.wantedBy = [ "initrd.target" ];
        boot.initrd.systemd.storePaths = [ "${cfg.package}/lib/systemd/systemd-pcrextend" ];
      }
    )
  ];
}
