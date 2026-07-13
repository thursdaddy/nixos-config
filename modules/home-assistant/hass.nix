{ inputs, ... }:
{
  flake.modules.nixos.home-assistant =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
      inherit (config.mine.base) user;
      subdomain = "home";
    in
    {
      options.mine.services.home-assistant = {
        enable = lib.mkOption {
          description = "Enable Home-Assistant";
          type = lib.types.bool;
          default = true;
        };
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = subdomain;
        };
      };

      disabledModules = [ "services/home-automation/home-assistant.nix" ];
      imports = [ "${inputs.unstable}/nixos/modules/services/home-automation/home-assistant.nix" ];

      config = {
        mine = {
          services = {
            appdaemon = enabled;
            govee2mqtt = enabled;
            mqtt = enabled;
            zigbee2mqtt = enabled;
          };
          homelab.${config.networking.hostName} = {
            apps.hass = {
              traefik.static = {
                hass = {
                  port = 8090;
                  subDomain = "home";
                  labels = {
                    "traefik.http.routers.hass.middlewares" = "fail2ban,teslarewrite";
                    "traefik.http.middlewares.teslarewrite.replacepathregex.regex" = "^/.well-known/appspecific/com.tesla.3p.public-key.pem$";
                    "traefik.http.middlewares.teslarewrite.replacepathregex.replacement" = "/local/tesla/com.tesla.3p.public-key.pem";
                    "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.bantime" = "3h";
                    "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.findtime" = "5m";
                    "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.maxretry" = "5";
                    "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.statuscode" = "401";
                    "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.enabled" = "true";
                  };
                };
                esphome = {
                  port = 6052;
                };
              };
            };
          };
        };

        users.users.${user.name}.extraGroups = [ "hass" ];

        environment.systemPackages = with pkgs; [
          esptool
          wakeonlan
        ];

        services = {
          postgresql = {
            enable = true;
            ensureDatabases = [ "hass" ];
            ensureUsers = [
              {
                name = "hass";
                ensureDBOwnership = true;
              }
            ];
          };

          home-assistant = {
            enable = true;
            package = (
              pkgs.unstable.home-assistant.override {
                extraPackages =
                  py: with py; [
                    aioacaia
                    google-nest-sdm
                    govee-ble
                    govee-local-api
                    grpcio
                    grpcio-tools
                    psutil-home-assistant
                    psycopg2
                    zlib-ng
                    kegtron-ble
                  ];
              }
            );
            lovelaceConfigWritable = true;
            openFirewall = true;
            config = {
              api = { };
              default_config = { };
              homeassistant = {
                name = "thurs_home";
                time_zone = config.time.timeZone;
                unit_system = "us_customary";
                temperature_unit = "F";
              };
              http = {
                server_port = 8090;
                use_x_forwarded_for = true;
                trusted_proxies = [
                  "127.0.0.1"
                  "100.64.0.0/10" # Tailscale subnet
                  "192.168.10.0/24" # Local LAN subnet
                ];
              };
              input_boolean = "!include booleans.yaml";
              notify = "!include notify.yaml";
              google_assistant = "!include google_assistant.yaml";
              lovelace.resource_mode = "yaml";
              prometheus = {
                namespace = "hass";
              };
              recorder.db_url = "postgresql://@/hass";
              mcp_server = {
                exposed_domains = [
                  "binary_sensor"
                  "climate"
                  "device_tracker"
                  "input_boolean"
                  "light"
                  "lock"
                  "person"
                  "sensor"
                  "switch"
                ];
              };
              "switch projector" = "!include projector.yaml";
              sensor = "!include sensor.yaml";
              template = "!include template.yaml";
              utility_meter = "!include utility.yaml";
            };
            customComponents = [
              pkgs.hass-gotify
            ];
            customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
              apexcharts-card
            ];
            extraComponents = [
              "alert"
              "default_config"
              "device_tracker"
              "esphome"
              "geo_location"
              "google_assistant"
              "google_assistant_sdk"
              "gpslogger"
              "history"
              "history_stats"
              "homeassistant"
              "homeassistant_alerts"
              "ibeacon"
              "logbook"
              "logger"
              "lovelace"
              "lutron_caseta"
              "mcp"
              "mcp_server"
              "met"
              "nws"
              "octoprint"
              "ping"
              "prometheus"
              "roborock"
              "sun"
              "telnet"
              "tesla_fleet"
              "tplink"
              "unifi"
              "unifiprotect"
              "webhook"
              "utility_meter"
              "zha" # not using but clears home-assistant startup error
            ];
          };
        };

        sops = {
          secrets = {
            "gotify/URL" = { };
            "gotify/token/HASS" = { };
            "google_assistant/SERVICE_ACCOUNT.JSON" = {
              path = "/var/lib/hass/SERVICE_ACCOUNT.json";
              owner = "hass";
              restartUnits = [ "home-assistant.service" ];
            };
            "google_assistant/PROJECT_ID" = { };
          };
          templates = {
            "notify.yaml" = {
              path = "/var/lib/hass/notify.yaml";
              owner = "hass";
              restartUnits = [ "home-assistant.service" ];
              content = ''
                - name: "gotify"
                  platform: gotify
                  url: ${config.sops.placeholder."gotify/URL"}
                  token: ${config.sops.placeholder."gotify/token/HASS"}
              '';
            };
            "google_assistant.yaml" = {
              path = "/var/lib/hass/google_assistant.yaml";
              owner = "hass";
              restartUnits = [ "home-assistant.service" ];
              content = ''
                project_id: ${config.sops.placeholder."google_assistant/PROJECT_ID"}
                service_account: !include SERVICE_ACCOUNT.json
                report_state: true
                exposed_domains:
                  - switch
                  - light
                  - input_boolean
              '';
            };
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs;
              name = "backup-home-assistant";
              extraEnv = {
                HOMELAB_BACKUP_ENABLE = "true";
                HOMELAB_BACKUP_PATH = "/var/lib/hass/backups";
              };
            };

            cfgDir = config.services.home-assistant.configDir;
            booleans = pkgs.writeText "booleans" (builtins.readFile ./configs/booleans.yaml);
            projector = pkgs.writeText "projector" (builtins.readFile ./configs/projector.yaml);
            sensor = pkgs.writeText "sensor" (builtins.readFile ./configs/sensor.yaml);
            template = pkgs.writeText "template" (builtins.readFile ./configs/template.yaml);
            utility = pkgs.writeText "utility" (builtins.readFile ./configs/utility.yaml);
          in
          {
            services."backup-home-assistant" = backup.service;
            timers."backup-home-assistant" = backup.timer;
            services.home-assistant.restartTriggers = [
              booleans
              projector
              sensor
              template
              utility
            ];
            tmpfiles.rules = [
              "f ${cfgDir}/automations.yaml 0400 hass hass -"
              "L+ ${cfgDir}/booleans.yaml 0400 hass hass - ${booleans}"
              "L+ ${cfgDir}/projector.yaml 0400 hass hass - ${projector}"
              "L+ ${cfgDir}/sensor.yaml 0400 hass hass - ${sensor}"
              "L+ ${cfgDir}/template.yaml 0400 hass hass - ${template}"
              "L+ ${cfgDir}/utility.yaml 0400 hass hass - ${utility}"
            ];
          };

        environment.etc =
          let
            name = "hass";
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "home-assistant";
            };
            alloyFileMatch = lib.thurs.mkAlloyFileMatch {
              inherit config;
              inherit name;
              path = "/var/lib/hass/home-assistant.log";
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-home-assistant";
              serviceName = "backup-home-assistant";
            };
          in
          builtins.listToAttrs [
            alloyJournal
            alloyFileMatch
            alloyJournalBackup
          ];
      };
    };
}
