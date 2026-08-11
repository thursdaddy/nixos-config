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
            # Workaround for upstream regression in zigbee-herdsman-converters (introduced in June 2026).
            # Upstream completely removed ZCL reporting (fz.lock) for Wyze WLCKG1 (Ford) to avoid the hourly false locked state report,
            # assuming the lock always reports state via raw cluster 64512 frames.
            # However, under this lock's firmware/setup, it does not send those raw frames during operation and only reports via ZCL.
            # wyze_lock.js restores the standard fz.lock converter so state updates function correctly.
            # TODO: PR a proper fix upstream that filters false hourly check-ins instead of disabling ZCL reporting entirely.
            external_converters = [
              "wyze_lock.js"
            ];
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
              };
            };
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        mine.homelab.${config.networking.hostName} = {
          apps.hass = {
            traefik.static = {
              z2m = {
                inherit port;
              };
            };
          };
        };

        environment.etc =
          let
            alloyZ2MQTT = lib.thurs.mkAlloyJournal {
              inherit name;
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          builtins.listToAttrs [
            alloyZ2MQTT
            alloyJournalBackup
          ];
      };
    };
}
