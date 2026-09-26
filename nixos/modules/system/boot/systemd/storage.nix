{ config, lib, ... }:

let
  cfg = config.systemd.storageProviders;
in
{
  options.systemd.storageProviders.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    example = true;
    description = ''
      Whether to enable {manpage}`systemd-storage-fs@.service(8)` and
      {manpage}`systemd-storage-block@.service(8)`, which expose regular files
      and directories in {file}`/var/lib/storage` and block devices as storage
      volumes, e.g. for {manpage}`systemd-vmspawn(1)`.

      Their sockets are accessible to all local users, and every connection
      spawns a service running as root. Acquiring a volume requires
      authorization through polkit, but listing volumes does not.
    '';
  };

  config = lib.mkIf cfg.enable {
    systemd.additionalUpstreamSystemUnits = [
      "systemd-storage-block@.service"
      "systemd-storage-block.socket"
      "systemd-storage-fs@.service"
      "systemd-storage-fs.socket"
    ];
  };
}
