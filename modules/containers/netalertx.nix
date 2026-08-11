_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "netalertx";
      version = "26.8.5";
      cfg = config.mine.containers.${name};
      hostName = config.networking.hostName;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        interface = lib.mkOption {
          type = lib.types.str;
          default = "eth0";
          description = "Physical network interface to scan";
        };
        subnet = lib.mkOption {
          type = lib.types.str;
          default = "192.168.10.0/24";
          description = "Subnet to scan";
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${hostName} = {
          apps.${name} = {
            traefik.static = {
              netalertx = {
                subDomain = "netalertx";
                port = 20211;
              };
            };
          };
        };

        networking.firewall.allowedTCPPorts = [ 20211 ];

        virtualisation.oci-containers.containers."${name}" = {
          image = "ghcr.io/netalertx/netalertx:latest";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          hostname = name;
          extraOptions = [
            "--network=host"
            "--cap-add=NET_ADMIN"
            "--cap-add=NET_RAW"
            "--cap-add=NET_BIND_SERVICE"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/${name}:/data"
          ];
          environment = {
            TZ = config.time.timeZone;
            PORT = "20211";
            PUID = "1000";
            PGID = "100";
            APP_CONF_OVERRIDE = "{\"SCAN_SUBNETS\":\"['${cfg.subnet} --interface=${cfg.interface}']\"}";
          };
          labels = {
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}";
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs name;
            };
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
            "${alloyJournalBackup.name}" = alloyJournalBackup.value;
          };
      };
    };
}
