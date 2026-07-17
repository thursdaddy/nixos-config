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
        };

        containers = {
          settings.backend = "podman";
          immich = enabled;
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
