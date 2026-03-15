_: {
  configurations.nixos.jupiter.module =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
    in
    {
      mine = {
        base = {
          networking = {
            hostName = "jupiter";
            meta = {
              hostIp = "192.168.10.15";
            };
          };
        };

        containers = {
          audiobookshelf = enabled;
          commafeed = enabled;
          gitlab = enabled;
          greenbook = enabled;
          hoarder = enabled;
          open-webui = enabled;
          paperless = enabled;
          teslamate = enabled;
          thelounge = enabled;
          traefik = enabled;
          vaultwarden = enabled;
        };

        services = {
          backups = enabled;
          ollama = enabled;
          qemu-guest = enabled;
        };
      };
    };
}
