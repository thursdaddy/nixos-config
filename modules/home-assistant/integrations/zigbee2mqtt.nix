_: {
  flake.modules.nixos.home-assistant =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      name = "zigbee2mqtt";
      port = 8080;
      subdomain = "z2m";
      cfg = config.mine.services.${name};
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = subdomain;
        };
      };

      config = lib.mkIf cfg.enable {
        services.zigbee2mqtt = {
          enable = true;
          settings = {
            frontend = {
              enabled = true;
              host = "0.0.0.0";
              port = port;
            };
            mqtt = {
              base_topic = "zigbee2mqtt";
              server = "mqtt://localhost:1883";
              user = "zigbee";
              password = "!secret password";
            };
            permit_join = false;
            serial = {
              port = "/dev/ttyUSB0";
            };
          };
        };

        sops = {
          templates = {
            "z2m_secret.yaml" = {
              owner = "zigbee2mqtt";
              path = "/var/lib/zigbee2mqtt/secret.yaml";
              content = ''
                password: ${config.sops.placeholder."mqtt/USER_PASS"}
              '';
            };
          };
        };

        networking.firewall.allowedTCPPorts = [
          port
        ];

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs;
              name = "backup-${name}";
              extraEnv = {
                HOMELAB_BACKUP_ENABLE = "true";
                HOMELAB_BACKUP_PATH = "/var/lib/${name}";
                HOMELAB_BACKUP_RETENTION_PERIOD = "5";
              };
            };
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        environment.etc =
          let
            alloyZ2MQTT = lib.thurs.mkAlloyJournal {
              inherit name;
            };
            traefikZ2MQTT = lib.thurs.mkTraefikFile {
              inherit config;
              name = subdomain;
              inherit port;
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          builtins.listToAttrs [
            alloyZ2MQTT
            alloyJournalBackup
            traefikZ2MQTT
          ];
      };
    };
}
