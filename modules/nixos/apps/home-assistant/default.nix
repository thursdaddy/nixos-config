{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.thurs) enabled;
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

    services.home-assistant = {
      enable = true;
      config.http.server_port = 8090;
      package =
        (pkgs.unstable.home-assistant.override {
          extraPackages =
            py: with py; [
              google-nest-sdm
              grpcio
              grpcio-tools
              psutil-home-assistant
              psycopg2
            ];
        }).overrideAttrs
          (oldAttrs: {
            doInstallCheck = false;
          });
      config.recorder.db_url = "postgresql://@/hass";
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
          unit_system = "imperial";
          temperature_unit = "F";
        };
        prometheus = {
          namespace = "hass";
        };
        "switch projector" = "!include projector.yaml";
        input_boolean = "!include booleans.yaml";
      };
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
        "zha" # not using but clears home-assistant startup error
      ];
    };

    systemd.tmpfiles.rules = [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
    ];

    environment.etc = mkIf config.mine.container.traefik.enable {
      "traefik/hass.yml" = {
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
    };

    sops = {
      secrets = {
        "hass/APPD_TOKEN" = { };
        "hass/LONGITUDE" = { };
        "hass/LATITUDE" = { };
      };
      templates = {
        # abusing sops-nix templates for hass config files
        "projector.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/projector.yaml";
          content = builtins.readFile ./configs/projector.yaml;
        };
        "booleans.yaml" = {
          owner = "hass";
          path = "/var/lib/hass/booleans.yaml";
          content = builtins.readFile ./configs/booleans.yaml;
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
