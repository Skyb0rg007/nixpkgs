{ config, lib, ... }:

let
  cfg = config.systemd.imds;
in
{
  options.systemd.imds.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = ''
      Whether to enable {manpage}`systemd-imdsd@.service(8)`, which provides
      access to the instance metadata service (IMDS) of cloud providers, and
      can import system credentials and configure networking from it.

      The IMDS units are pulled in by
      {manpage}`systemd-imds-generator(8)` when running on a supported cloud,
      or when `systemd.imds=1` is set on the kernel command line.
    '';
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.systemd.package.withImds;
        message = "systemd.imds.enable requires systemd to be built with IMDS support.";
      }
    ];

    systemd.additionalUpstreamSystemUnits = [
      "systemd-imdsd.socket"
      "systemd-imdsd@.service"
      "systemd-imds-early-network.service"
      "systemd-imds-import.service"
      "systemd-imds-metrics.socket"
      "systemd-imds-metrics@.service"
    ];

    users.users.systemd-imds = {
      isSystemUser = true;
      group = "systemd-imds";
    };
    users.groups.systemd-imds = { };
  };
}
