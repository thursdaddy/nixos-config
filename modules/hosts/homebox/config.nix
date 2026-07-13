_: {
  configurations.nixos.homebox.module =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
      inherit (config.mine.base) user;
    in
    {
      mine = {
        base = {
          bluetooth = enabled;
          networking = {
            hostName = "homebox";
            wake-on-lan = {
              enable = true;
              interface = "eno1";
            };
          };
        };

        homelab.homebox = {
          hostIp = "192.168.10.60";
          tailscaleIp = "100.96.164.35";
          apps = {
            syncthing.traefik.static.syncthing.labels = {
              "traefik.http.routers.syncthing.middlewares" = "local-only";
            };
            hass.traefik.static.z2m.labels = {
              "traefik.http.routers.z2m.middlewares" = "local-only";
            };
            hass.traefik.static.esphome.labels = {
              "traefik.http.routers.esphome.middlewares" = "local-only";
            };
          };
        };
        services = {
          backups = enabled;
          gitea-runner = {
            enable = true;
            runners = {
              "${config.networking.hostName}" = {
                labels = [
                  "runner:docker://gitea.thurs.pw/docker/gitea-runner:v0.3.0"
                ];
                settings = {
                  runner = {
                    capacity = 4;
                  };
                };
              };
            };
          };
          sleep-on-lan = enabled;
          syncthing = {
            enable = true;
            folders = {
              "appd" = {
                path = "${user.homeDir}/appdaemon";
                devices = [
                  "mbp"
                  "c137"
                  "wormhole"
                ];
                ignorePerms = true;
              };
            };
          };
          traefik = {
            enable = true;
            dnsChallengeProvider = "gcp";
            extraCmds = [
              "--entrypoints.tailscale.address=:8443"
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
          };
        };
      };
      
      environment.etc."traefik/static/tesla-key.yaml".text = ''
        http:
          routers:
            tesla-key:
              rule: "Host(`homebox.fable-pinecone.ts.net`) && PathPrefix(`/.well-known/appspecific/com.tesla.3p.public-key.pem`)"
              service: "tesla-key"
              entryPoints:
                - "tailscale"
              middlewares:
                - "teslarewrite"
          middlewares:
            teslarewrite:
              replacePathRegex:
                regex: "^/.well-known/appspecific/com.tesla.3p.public-key.pem$"
                replacement: "/local/tesla/com.tesla.3p.public-key.pem"
          services:
            tesla-key:
              loadBalancer:
                servers:
                  - url: "http://127.0.0.1:8090"
      '';
    };
}
