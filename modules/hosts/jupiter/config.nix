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
          pinepods = enabled;
          commafeed = enabled;
          greenbook = enabled;
          hoarder = enabled;
          mealie = enabled;
          navidrome = enabled;
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
          gitea-runner = {
            enable = true;
            runners = {
              ${config.networking.hostName} = {
                settings = {
                  runner = {
                    capacity = 10;
                  };
                  container = {
                    privileged = true;
                    force_pull = true;
                    volumes = [
                      "/var/run/docker.sock:/var/run/docker.sock"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
}
