_: {
  configurations.nixos.jupiter.module =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
      name = "traefik-${config.networking.hostName}";
      rootDomainName = config.mine.containers.traefik.rootDomainName;
    in
    {
      mine = {
        base = {
          networking = {
            hostName = "jupiter";
            meta = {
              hostIp = "192.168.10.15";
              tailscaleIp = "100.78.22.112";
            };
          };
        };

        containers = {
          commafeed = enabled;
          greenbook = enabled;
          hoarder = enabled;
          mealie = enabled;
          open-webui = enabled;
          paperless = enabled;
          sparkyfitness = enabled;
          teslamate = enabled;
          thelounge = enabled;
          traefik = {
            enable = true;
            ports = [
              "${config.mine.base.networking.meta.tailscaleIp}:443:8443"
              "${config.mine.base.networking.meta.hostIp}:443:443"
            ];
            extraCmds = [
              "--api=true"
              "--entrypoints.tailscale.address=:8443"
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
            extraLabels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.rule" =
                "Host(`${name}.${rootDomainName}`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`) || Path(`/`))";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.service" = "api@internal";
            };
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
