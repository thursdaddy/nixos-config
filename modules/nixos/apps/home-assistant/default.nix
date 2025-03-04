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
        extraPackages = py: with py; [ psycopg2 psutil-home-assistant ];
      }).overrideAttrs (oldAttrs: {
        doInstallCheck = false;
      });
      config.recorder.db_url = "postgresql://@/hass";
      openFirewall = true;
      config = {
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [ "0.0.0.0/0" ];
        };
        logger = {
          default = "info";
        };
        default_config = { };
        automation = "!include automations.yaml";
        prometheus = {
          namespace = "hass";
        };
        api = { };
      };
      extraComponents = [
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
        "logbook"
        "logger"
        "lutron_caseta"
        "met"
        "mqtt"
        "nws"
        "prometheus"
        "roborock"
        "tplink"
        "unifi"
        "unifiprotect"
        "zha" # not using but clears home-assistant startup error
      ];
    };

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

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "hass" ];
      ensureUsers = [{
        name = "hass";
        ensureDBOwnership = true;
      }];
    };

    sops = {
      secrets = {
        "mqtt/USER_PASS" = {
          owner = "mosquitto";
        };
        "hass/APPD_TOKEN" = { };
        "hass/LONGITUDE" = { };
        "hass/LATITUDE" = { };
      };
      templates = {
        "appdaemon_conf" = {
          path = "/var/lib/appdaemon/appdaemon.yaml";
          content = ''
            appdaemon:
              time_zone: ${config.mine.system.timezone.location}
              latitude: ${config.sops.placeholder."hass/LATITUDE"}
              longitude: ${config.sops.placeholder."hass/LONGITUDE"}
              elevation: 1,211
              plugins:
                MQTT:
                  type: mqtt
                  namespace: mqtt
                  client_user: zigbee
                  client_password: ${config.sops.placeholder."mqtt/USER_PASS"}
                HASS:
                  type: hass
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
      };
    };

    networking.firewall.allowedTCPPorts = [
      1883
      8123
      6052
    ];

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
        };
        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtt://localhost:1883";
          user = "zigbee";
          password = "!secret password";
        };
        permit_join = false;
        serial = {
          port = "/dev/ttyUSB1";
        };
      };
    };

    services.esphome.enable = true;

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
