{ lib, config, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.home-assistant;
in
{
  options.mine.apps.home-assistant = {
    enable = mkEnableOption "Install Home-Assistant";
  };

  config = mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      config.http.server_port = 8090;
      package = (pkgs.unstable.home-assistant.override {
        extraPackages = py: with py; [
          google-nest-sdm
          grpcio
          grpcio-tools
          psutil-home-assistant
          psycopg2
        ];
      }).overrideAttrs (oldAttrs: {
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
        "mqtt"
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
        text = (builtins.readFile
          (pkgs.substituteAll {
            name = "hass";
            src = ./traefik.yml;
            fqdn = config.mine.container.traefik.domainName;
            ip = "192.168.10.60";
          })
        );
      };
    };

    sops = {
      secrets = {
        "mqtt/USER_PASS" = {
          owner = "mosquitto";
        };
        "hass/APPD_TOKEN" = { };
        "hass/LONGITUDE" = { };
        "hass/LATITUDE" = { };
        "govee/EMAIL" = { };
        "govee/PASSWORD" = { };
        "govee/API_KEY" = { };
      };
      templates = {
        "appdaemon_conf" = {
          path = "/var/lib/appdaemon/appdaemon.yaml";
          content = ''
            appdaemon:
              time_zone: ${config.mine.system.timezone.location}
              latitude: ${config.sops.placeholder."hass/LATITUDE"}
              longitude: ${config.sops.placeholder."hass/LONGITUDE"}
              elevation: 1211
              plugins:
                MQTT:
                  type: mqtt
                  namespace: mqtt
                  client_user: zigbee
                  client_password: ${config.sops.placeholder."mqtt/USER_PASS"}
                HASS:
                  type: hass
                  namespace: default
                  ha_url: https://home.${config.nixos-thurs.localDomain}
                  token: ${config.sops.placeholder."hass/APPD_TOKEN"}
          '';

        };
        "z2m_secret.yaml" = {
          owner = "zigbee2mqtt";
          path = "/var/lib/zigbee2mqtt/secret.yaml";
          content = ''
            password: ${config.sops.placeholder."mqtt/USER_PASS"}
          '';
        };
        "govee.env" = {
          path = "/var/lib/govee2mqtt/govee2mqtt.env";
          content = ''
            GOVEE_EMAIL=${config.sops.placeholder."govee/EMAIL"}
            GOVEE_PASSWORD=${config.sops.placeholder."govee/PASSWORD"}
            GOVEE_API_KEY=${config.sops.placeholder."govee/API_KEY"}
            GOVEE_MQTT_HOST=localhost
            GOVEE_MQTT_USER=zigbee
            GOVEE_MQTT_PASSWORD=${config.sops.placeholder."mqtt/USER_PASS"}
          '';
        };
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

    networking.firewall.allowedTCPPorts = [
      8123
      8080
      1883
    ];

    services.govee2mqtt = {
      enable = true;
      environmentFile = config.sops.templates."govee.env".path;
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "hass" ];
      ensureUsers = [{
        name = "hass";
        ensureDBOwnership = true;
      }];
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

    services.zigbee2mqtt = {
      enable = true;
      settings = {
        homeassistant = true;
        frontend = {
          enabled = true;
          host = "0.0.0.0";
          port = 8080;
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

    services.esphome = {
      enable = true;
      address = "192.168.10.60";
      openFirewall = true;
    };

    systemd.services.appdaemon = {
      description = "Start AppDaemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.appdaemon}/bin/appdaemon -c /var/lib/appdaemon/";
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "3s";
      };
    };
  };
}

