_: {
  configurations.nixos.streambox.module =
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
        base.networking.hostName = "streambox";

        homelab.streambox = {
          hostIp = "192.168.10.189";
          tailscaleIp = "100.89.208.50";
          apps.tesla-key = {
            traefik.static.tesla-key = {
              subDomain = "home";
              dns = false;
              ip = "100.96.164.35";
              port = 8090;
              labels = {
                "traefik.http.routers.tesla-key.rule" =
                  "Host(`home.${config.mine.homelab.streambox.rootDomainName}`) && PathPrefix(`/.well-known/appspecific/com.tesla.3p.public-key.pem`)";
                "traefik.http.routers.tesla-key.middlewares" = "teslarewrite";
                "traefik.http.middlewares.teslarewrite.replacepathregex.regex" =
                  "^/.well-known/appspecific/com.tesla.3p.public-key.pem$";
                "traefik.http.middlewares.teslarewrite.replacepathregex.replacement" =
                  "/local/tesla/com.tesla.3p.public-key.pem";
              };
            };
          };
        };

        containers = {
          settings.backend = "podman";
          jellyfin = enabled;
          jellystat = enabled;
          navidrome = enabled;
          nextpvr = enabled;
          pinepods = enabled;
          seerr = enabled;
          tracearr = enabled;
          traefik = {
            enable = true;
            dashboard = true;
            dnsChallengeProvider = "gcp";
            extraCmds = [
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
          };
        };

        services = {
          backups = enabled;
          ddns = enabled;
          mpd = enabled;
        };
      };

      services.resolved = {
        extraConfig = ''
          MulticastDNS=no
        '';
      };
    };
}
