{
  config,
  pkgs,
  lib,
  ...
}:
let

  cfg = config.services.cascade;

  cascaded = lib.getExe' cfg.package "cascaded";

  configContent = lib.generators.toKeyValue { } cfg.settings;

  configFile = pkgs.writeFile "cascade.toml" configContent;
in
{
  options.services.cascade = {
    enable = lib.mkEnableOption "Cascade DNSSEC Signer";

    package = lib.mkPackageOption pkgs "cascade" { };

    settings = lib.mkOption {
      type = lib.types.attrset;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cascade = {
      description = "Cascade DNSSEC Signer";
      documentation = "man:cascade(1)";
      after = [ "network.target" ];
      requires = [ "cascaded.socket" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Restart = "on-failure";
        # AmbientCapabilities = "CAP_NET_BIND_SERVICE";
        # CapabilityBoundingSet = "CAP_NET_BIND_SERVICE";
        StateDirectory = "cascade";
        ExecStart = "${cascaded} --state=\${STATE_DIRECTORY}/state.db --config=${configFile}";

        # Sandboxing
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitecture = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = [ "@system-service" ];
      };
    };
    systemd.sockets.cascade = {
      description = "Cascaded Sockets";
      wantedBy = [ "sockets.target" ];

      socketConfig = {
        Accept = false;
        ListenDatagram = [
          "127.0.0.1:53"
          "[::1]:53"
        ];
        ListenStream = [
          "127.0.0.1:53"
          "[::1]:53"
        ];
      };
    };
  };
}
