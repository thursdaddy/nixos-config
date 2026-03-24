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

      config = {
        mine.services = {
          appdaemon = enabled;
          govee2mqtt = enabled;
          mqtt = enabled;
          zigbee2mqtt = enabled;
        };

        users.users.${user.name}.extraGroups = [ "hass" ];

        environment.systemPackages = with pkgs; [
          esptool
          wakelan
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
            package =
              (pkgs.home-assistant.override {
                extraPackages =
                  py: with py; [
                    aioacaia
                    google-nest-sdm
                    govee-ble
                    grpcio
                    grpcio-tools
                    psutil-home-assistant
                    psycopg2
                    zlib-ng
                  ];
              }).overrideAttrs
                (oldAttrs: {
                  doInstallCheck = false;
                });
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
                  "0.0.0.0/0"
                ];
              };
              input_boolean = "!include booleans.yaml";
              lovelace.mode = "yaml";
              notify = "!include notify.yaml";
              prometheus = {
                namespace = "hass";
              };
              recorder.db_url = "postgresql://@/hass";
              "switch projector" = "!include projector.yaml";
              sensor = "!include sensor.yaml";
              template = "!include template.yaml";
              utility_meter = "!include utility.yaml";
            };
            customComponents = [
              inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.hass-gotify
            ];
            customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
              apexcharts-card
            ];
            extraComponents = [
              "alert"
              "bluetooth_tracker"
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
              "met"
              "nws"
              "octoprint"
              "ping"
              "prometheus"
              "roborock"
              "sun"
              "telnet"
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
          };
          templates = {
            "notify.yaml" = {
              path = "/var/lib/hass/notify.yaml";
              owner = "hass";
              content = ''
                - name: "gotify"
                  platform: gotify
                  url: ${config.sops.placeholder."gotify/URL"}
                  token: ${config.sops.placeholder."gotify/token/HASS"}
              '';
            };
          };
        };

        nixpkgs.config.permittedInsecurePackages = [
          "python3.12-ecdsa-0.19.1"
        ];

        systemd.tmpfiles.rules =
          let
            cfgDir = config.services.home-assistant.configDir;
            booleans = pkgs.writeText "booleans" (builtins.readFile ./configs/booleans.yaml);
            projector = pkgs.writeText "projector" (builtins.readFile ./configs/projector.yaml);
            sensor = pkgs.writeText "sensor" (builtins.readFile ./configs/sensor.yaml);
            template = pkgs.writeText "template" (builtins.readFile ./configs/template.yaml);
            utility = pkgs.writeText "utility" (builtins.readFile ./configs/utility.yaml);
          in
          [
            "f ${cfgDir}/automations.yaml 0400 hass hass -"
            "L+ ${cfgDir}/booleans.yaml 0400 hass hass - ${booleans}"
            "L+ ${cfgDir}/projector.yaml 0400 hass hass - ${projector}"
            "L+ ${cfgDir}/sensor.yaml 0400 hass hass - ${sensor}"
            "L+ ${cfgDir}/template.yaml 0400 hass hass - ${template}"
            "L+ ${cfgDir}/utility.yaml 0400 hass hass - ${utility}"
          ];

        environment.etc =
          let
            name = "hass";
            traefikHass = lib.thurs.mkTraefikFile {
              inherit config;
              name = subdomain;
              port = 8090;
            };
            traefikEspHome = lib.thurs.mkTraefikFile {
              inherit config;
              name = "esphome";
              port = 6052;
            };
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "home-assistant";
            };
            alloyFileMatch = lib.thurs.mkAlloyFileMatch {
              inherit config;
              inherit name;
              path = "/var/lib/hass/home-assistant.log";
            };
          in
          builtins.listToAttrs [
            traefikHass
            traefikEspHome
            alloyJournal
            alloyFileMatch
          ];
      };
    };
}
