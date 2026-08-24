{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.blueferry;
in
{
  options.programs.blueferry = {
    enable = lib.mkEnableOption "blueferry iOS notification bridge";

    frontends = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "gtk"
          "qt"
          "quickshell"
        ]
      );
      default = [ "gtk" ];
      example = [ "qt" ];
      description = ''
        Desktop frontends to install alongside the backend. The command line
        interface, the terminal interface and the daemon are always installed.

        This has no effect if {option}`programs.blueferry.package` is set.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.blueferry.override {
        withGtk = lib.elem "gtk" cfg.frontends;
        withQt = lib.elem "qt" cfg.frontends;
        withQuickshell = lib.elem "quickshell" cfg.frontends;
      };
      defaultText = lib.literalExpression ''
        pkgs.blueferry.override {
          withGtk = lib.elem "gtk" config.programs.blueferry.frontends;
          withQt = lib.elem "qt" config.programs.blueferry.frontends;
          withQuickshell = lib.elem "quickshell" config.programs.blueferry.frontends;
        }
      '';
      description = "The blueferry package to use.";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to start the per-user daemon on login. The unit only starts for
        users that completed pairing; others are skipped by its
        `ConditionPathExists`. When disabled, the daemon is still started on
        demand through D-Bus activation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    systemd.packages = [ cfg.package ];
    services.dbus.packages = [ cfg.package ];

    systemd.user.services.blueferry.wantedBy = lib.mkIf cfg.autoStart [ "default.target" ];

    # Overrides the systemd1.manage-units operation to use AUTH_ADMIN (no keep)
    # for blueferry's specific operation.
    security.polkit.enable = lib.mkDefault true;
    environment.etc."polkit-1/rules.d/49-blueferry-cod.rules".source =
      "${cfg.package}/share/polkit-1/rules.d/49-blueferry-cod.rules";

    hardware.bluetooth = {
      enable = lib.mkDefault true;
      package = lib.mkDefault pkgs.bluez-experimental;
      settings.General.Experimental = true;
    };
  };

  meta.maintainers = with lib.maintainers; [ skyesoss ];
}
