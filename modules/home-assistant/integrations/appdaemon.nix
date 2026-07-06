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
      appDir = "${config.mine.base.user.homeDir}/appdaemon/";
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
            User = config.mine.base.user.name;
            LogsDirectory = "appdaemon";
            # Run appdaemon pointing to the appDir config directory
            ExecStart = "${pkgs.appdaemon}/bin/appdaemon -c ${appDir}";
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
              path = "${appDir}/appdaemon.yaml";
              owner = config.mine.base.user.name;
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
                    filename: /var/log/appdaemon/main.log
                  access_log:
                    filename: /var/log/appdaemon/access.log
                  error_log:
                    filename: /var/log/appdaemon/error.log
                  diag_log:
                    filename: /var/log/appdaemon/diag.log
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
              path = "/var/log/appdaemon/*.log";
            };
          in
          builtins.listToAttrs [
            alloyAppDaemon
          ];
      };
    };
}
