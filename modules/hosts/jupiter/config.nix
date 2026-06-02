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
        base.networking.hostName = "jupiter";

        homelab.jupiter = {
          hostIp = "192.168.10.15";
          tailscaleIp = "100.78.22.112";
          apps.vaultwarden.traefik.container.tailscale = lib.mkForce false;
        };

        containers = {
          settings.backend = "podman";
          commafeed = enabled;
          greenbook = enabled;
          hoarder = enabled;
          mealie = enabled;
          open-webui = enabled;
          paperless = enabled;
          sparkyfitness = enabled;
          teslamate = enabled;
          thelounge = enabled;
          seerr = enabled;
          traefik = {
            enable = true;
            dashboard = true;
            extraPorts = [
              "${config.mine.homelab.jupiter.tailscaleIp}:443:8443"
              "${config.mine.homelab.jupiter.hostIp}:443:443"
            ];
            extraCmds = [
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
          };
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
                    force_pull = true;
                  };
                };
              };
            };
          };
        };
      };
    };
}
