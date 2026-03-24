_: {
  flake.modules.nixos.home-assistant =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      name = "appdaemon";
      cfg = config.mine.services.${name};
    in
    {
      options.mine.services.appdaemon = {
        enable = lib.mkEnableOption "AppDaemon home-assistant python automation apps.";
      };

      config = lib.mkIf cfg.enable {
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

        sops = {
          secrets = {
            "hass/APPD_TOKEN" = { };
            "hass/LONGITUDE" = { };
            "hass/LATITUDE" = { };
          };
          templates = {
            "appdaemon_conf" = {
              path = "/var/lib/appdaemon/appdaemon.yaml";
              owner = "hass";
              content = ''
                appdaemon:
                  time_zone: ${config.time.timeZone}
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

        environment.etc =
          let
            alloyAppDaemon = lib.thurs.mkAlloyFileMatch {
              inherit config;
              inherit name;
              path = "/var/lib/appdaemon/**/*.log";
            };
          in
          builtins.listToAttrs [
            alloyAppDaemon
          ];
      };
    };
}
