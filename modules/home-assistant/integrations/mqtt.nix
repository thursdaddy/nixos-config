_: {
  flake.modules.nixos.home-assistant =
    {
      lib,
      config,
      ...
    }:
    let
      name = "mqtt";
      cfg = config.mine.services.${name};
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        services.home-assistant = {
          extraComponents = [
            "mqtt"
          ];
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

        networking.firewall.allowedTCPPorts = [
          1883
        ];

        sops = {
          secrets = {
            "mqtt/USER_PASS" = {
              owner = "mosquitto";
            };
          };
        };

        environment.etc =
          let
            alloyMQTT = lib.thurs.mkAlloyJournal {
              name = "mosquitto";
            };
          in
          builtins.listToAttrs [
            alloyMQTT
          ];
      };
    };
}
