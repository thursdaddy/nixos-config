{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.home-assistant.mqtt;
in
{
  options.mine.apps.home-assistant.mqtt = {
    enable = mkEnableOption "MQTT";
  };

  config = mkIf cfg.enable {

    services.home-assistant = {
      extraComponents = [
        "mqtt"
      ];
    };

    sops = {
      secrets = {
        "mqtt/USER_PASS" = {
          owner = "mosquitto";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [
      1883
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

    environment.etc."alloy/mqtt.alloy" = mkIf config.mine.services.alloy.enable {
      text = builtins.readFile ./config.alloy;
    };
  };
}
