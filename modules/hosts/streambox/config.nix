_: {
  configurations.nixos.streambox.module =
    {
      config,
      lib,
      pkgs,
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
          audiobookshelf = enabled;
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
            enableCrowdsec = true;
            extraCmds = [
              "--accesslog=true"
              "--experimental.plugins.bouncer.modulename=github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
              "--experimental.plugins.bouncer.version=v1.6.0"
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
        settings = {
          Resolve = {
            MulticastDNS = "no";
          };
        };
      };
    };
}
