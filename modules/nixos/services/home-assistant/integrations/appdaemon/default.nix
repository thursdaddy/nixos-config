{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.home-assistant.appdaemon;
in
{
  options.mine.services.home-assistant.appdaemon = {
    enable = mkEnableOption "AppDaemon home-assistant python automation apps.";
  };

  config = mkIf cfg.enable {
    sops = {
      templates = {
        "appdaemon_conf" = {
          path = "/var/lib/appdaemon/appdaemon.yaml";
          owner = "hass";
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
                  ha_url: https://home.thurs.pw
                  token: ${config.sops.placeholder."hass/APPD_TOKEN"}
            logs:
              main_log:
                filename: /var/lib/appdaemon/logs/main.log
              access_log:
                filename: /var/lib/appdaemon/logs/access.log
              error_log:
                filename: /var/lib/appdaemon/logs/error.log
              diag_log:
                filename: /var/lib/appdaemon/logs/diag.log
                log_generations: 5
                log_size: 1024
                format: "{asctime} {levelname:<8} {appname:<10}: {message}"
          '';
        };
      };
    };

    systemd.services.appdaemon = {
      description = "Start AppDaemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "hass";
        ExecStart = "${pkgs.appdaemon}/bin/appdaemon -c /var/lib/appdaemon/";
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "3s";
      };
    };

    environment.etc."alloy/appdaemon.alloy" = mkIf config.mine.services.alloy.enable {
      text = builtins.readFile (
        pkgs.replaceVars ./config.alloy {
          host = config.networking.hostName;
        }
      );
    };
  };
}
