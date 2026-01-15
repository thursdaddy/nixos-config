{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.home-assistant.zigbee2mqtt;
in
{
  options.mine.services.home-assistant.zigbee2mqtt = {
    enable = mkEnableOption "Zigbee2MQTT";
  };

  config = mkIf cfg.enable {

    sops = {
      templates = {
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
      8080
    ];

    services.zigbee2mqtt = {
      enable = true;
      settings = {
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

    environment.etc."alloy/zigbee2mqtt.alloy" = mkIf config.mine.services.alloy.enable {
      text = builtins.readFile ./config.alloy;
    };
  };
}
