{ config, lib, ... }:

let
  cfg = config.boot.initrd.systemd;
in
{
  options.boot.initrd.systemd.cryptenroll.firstboot.enable = lib.mkEnableOption ''
    the interactive disk encryption setup in the initrd on first boot. When
    the file system backing {file}`/var` is encrypted and
    {file}`/etc/machine-id` is not initialized yet, it offers to enroll a
    passphrase, a recovery key or a FIDO2 token, unless one is already
    enrolled. See the `--firstboot` option of
    {manpage}`systemd-cryptenroll(1)`
  '';

  config = lib.mkIf (cfg.enable && cfg.cryptenroll.firstboot.enable) {
    assertions = [
      {
        assertion = cfg.package.withCryptsetup;
        message = "boot.initrd.systemd.cryptenroll.firstboot.enable requires systemd to be built with cryptsetup support.";
      }
    ];

    boot.initrd.systemd = {
      additionalUpstreamUnits = [ "systemd-cryptenroll-firstboot.service" ];
      services.systemd-cryptenroll-firstboot.wantedBy = [ "initrd.target" ];

      extraBin.systemd-cryptenroll = "${cfg.package}/bin/systemd-cryptenroll";
      storePaths = [
        {
          # systemd-cryptenroll is a wrapper, and the wrapped binary dlopen()s
          # libcryptsetup, and libqrencode to show recovery keys as QR codes.
          source = "${cfg.package}/bin/.systemd-cryptenroll-wrapped";
          dlopen.features = [
            "cryptsetup"
            "qrencode"
          ];
        }
      ];
    };
  };
}
