{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.home-assistant.govee2mqtt;
in
{
  options.mine.apps.home-assistant.govee2mqtt = {
    enable = mkEnableOption "Govee2MQTT";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        "govee/EMAIL" = { };
        "govee/PASSWORD" = { };
        "govee/API_KEY" = { };
      };
      templates = {
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
      };
    };

    services.govee2mqtt = {
      enable = true;
      environmentFile = config.sops.templates."govee.env".path;
    };
  };
}
