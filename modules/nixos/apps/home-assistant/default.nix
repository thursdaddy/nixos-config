{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.thurs) enabled;
  inherit (config.mine) user;
  cfg = config.mine.apps.home-assistant;
in
{
  options.mine.apps.home-assistant = {
    enable = mkEnableOption "Install Home-Assistant along with Postgres, AppDaemon, Mosquitto, Zigbee2MQTT, Govee2MQTT and espHome";
  };

  config = mkIf cfg.enable {
    mine.apps.home-assistant = {
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
      esphome = {
        address = "192.168.10.60";
        enable = true;
        openFirewall = true;
      };
      home-assistant = {
        enable = true;
        package =
          (pkgs.home-assistant.override {
            extraPackages =
              py: with py; [
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
            time_zone = config.mine.system.timezone.location;
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
          inputs.self.packages.${pkgs.system}.homeassistant-gotify
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

    systemd.tmpfiles.rules = [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    ];

    environment.etc = {
      "traefik/hass.yml" = mkIf config.mine.container.traefik.enable {
        text = builtins.readFile (
          pkgs.replaceVars ./traefik.yml {
            fqdn = config.mine.container.traefik.domainName;
            ip = "192.168.10.60";
          }
        );
      };
      "alloy/home-assistant.alloy" = mkIf config.mine.services.alloy.enable {
        text = builtins.readFile (
          pkgs.replaceVars ./config.alloy {
            host = config.networking.hostName;
          }
        );
      };
    };

    sops = {
      secrets = {
        "hass/APPD_TOKEN" = { };
        "hass/LONGITUDE" = { };
        "hass/LATITUDE" = { };
        "gotify/URL" = { };
        "gotify/token/HASS" = { };
      };
      templates = {
        # abusing sops-nix templates for hass config files
        "projector.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/projector.yaml";
          content = builtins.readFile ./configs/projector.yaml;
        };
        "template.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/template.yaml";
          content = builtins.readFile ./configs/template.yaml;
        };
        "booleans.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/booleans.yaml";
          content = builtins.readFile ./configs/booleans.yaml;
        };
        "utility.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/utility.yaml";
          content = builtins.readFile ./configs/utility.yaml;
        };
        "sesnor.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/sensor.yaml";
          content = builtins.readFile ./configs/sensor.yaml;
        };
        "notify.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/notify.yaml";
          content = ''
            - name: "gotify"
              platform: gotify
              url: ${config.sops.placeholder."gotify/URL"}
              token: ${config.sops.placeholder."gotify/token/HASS"}
          '';
        };
      };
    };
  };
}
