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

    services.home-assistant = {
      enable = true;
      config.http.server_port = 8090;
      package =
        (pkgs.unstable.home-assistant.override {
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
      config.recorder.db_url = "postgresql://@/hass";
      lovelaceConfigWritable = true;
      openFirewall = true;
      config = {
        api = { };
        default_config = { };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [
            "0.0.0.0/0"
          ];
        };
        homeassistant = {
          name = "thurs_home";
          time_zone = config.mine.system.timezone.location;
          unit_system = "us_customary";
          temperature_unit = "F";
        };
        lovelace.mode = "yaml";
        prometheus = {
          namespace = "hass";
        };
        "switch projector" = "!include projector.yaml";
        input_boolean = "!include booleans.yaml";
        notify = "!include notify.yaml";
        sensor = "!include sensor.yaml";
        utility_meter = "!include utility.yaml";
        template = "!include template.yaml";
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

    systemd.tmpfiles.rules = [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    ];

    environment.etc = {
      "traefik/hass.yml" = mkIf config.mine.container.traefik.enable {
        text = (
          builtins.readFile (
            pkgs.substituteAll {
              name = "hass";
              src = ./traefik.yml;
              fqdn = config.mine.container.traefik.domainName;
              ip = "192.168.10.60";
            }
          )
        );
      };
      "alloy/home-assistant.alloy" = mkIf config.mine.services.alloy.enable {
        text = (
          builtins.readFile (
            pkgs.substituteAll {
              name = "home-assistant.alloy";
              src = ./config.alloy;
              host = config.networking.hostName;
            }
          )
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

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "hass" ];
      ensureUsers = [
        {
          name = "hass";
          ensureDBOwnership = true;
        }
      ];
    };

    services.esphome = {
      enable = true;
      address = "192.168.10.60";
      openFirewall = true;
    };

  };
}
