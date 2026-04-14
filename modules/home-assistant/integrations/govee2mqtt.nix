_: {
  flake.modules.nixos.home-assistant =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "govee2mqtt";
      cfg = config.mine.services.govee2mqtt;
    in
    {
      options.mine.services.govee2mqtt = {
        enable = lib.mkEnableOption "Govee2MQTT";
      };

      config = lib.mkIf cfg.enable {
        sops = {
          secrets = {
            "govee/EMAIL" = { };
            "govee/PASSWORD" = { };
            "govee/API_KEY" = { };
          };
          templates = {
            "govee.env" = {
              path = "/var/lib/govee2mqtt/govee2mqtt.env";
              content = ''
                GOVEE_API_KEY=${config.sops.placeholder."govee/API_KEY"}
                GOVEE_MQTT_HOST=localhost
                GOVEE_MQTT_USER=zigbee
                GOVEE_MQTT_PASSWORD=${config.sops.placeholder."mqtt/USER_PASS"}
              '';
            };
          };
        };

        services.govee2mqtt = {
          enable = true;
          environmentFile = config.sops.templates."govee.env".path;
        };

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
            alloyG2MQTT = lib.thurs.mkAlloyJournal {
              inherit name;
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          builtins.listToAttrs [
            alloyG2MQTT
            alloyJournalBackup
          ];
      };
    };
}
