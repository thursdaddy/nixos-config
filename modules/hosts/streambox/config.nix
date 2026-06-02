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
          services.ddns = true;
          hostIp = "192.168.10.189";
          tailscaleIp = "100.89.208.50";
        };

        containers = {
          settings.backend = "podman";
          jellyfin = enabled;
          jellystat = enabled;
          navidrome = enabled;
          pinepods = enabled;
          plex = enabled;
          tautulli = enabled;
          tracearr = enabled;
          traefik = {
            enable = true;
            dashboard = true;
            extraCmds = [
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
          };
        };

        services = {
          backups = enabled;
        };
      };

      services.resolved = {
        extraConfig = ''
          MulticastDNS=no
        '';
      };
    };
}
