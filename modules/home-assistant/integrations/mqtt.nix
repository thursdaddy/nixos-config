_: {
  flake.modules.nixos.home-assistant =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "mqtt";
      cfg = config.mine.services.${name};
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        services.home-assistant = {
          extraComponents = [
            "mqtt"
          ];
        };

        services.mosquitto = {
          enable = true;
          listeners = [
            {
              users.zigbee = {
                acl = [
                  "readwrite #"
                ];
                passwordFile = config.sops.secrets."mqtt/USER_PASS".path;
              };
            }
          ];
        };

        networking.firewall.allowedTCPPorts = [
          1883
        ];

        sops = {
          secrets = {
            "mqtt/USER_PASS" = {
              owner = "mosquitto";
            };
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs;
              name = "backup-${name}";
              extraEnv = {
                HOMELAB_BACKUP_ENABLE = "true";
                HOMELAB_BACKUP_PATH = "/var/lib/mosquitto";
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
            alloyMQTT = lib.thurs.mkAlloyJournal {
              name = "mosquitto";
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          builtins.listToAttrs [
            alloyMQTT
            alloyJournalBackup
          ];
      };
    };
}
