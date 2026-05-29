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
        base = {
          networking = {
            hostName = "streambox";
            meta = {
              hostIp = "192.168.10.189";
              tailscaleIp = "100.89.208.50";
            };
          };
        };

        containers = {
          jellyfin = enabled;
          jellystat = enabled;
          navidrome = enabled;
          pinepods = enabled;
          plex = enabled;
          tautulli = enabled;
          tracearr = enabled;
          traefik = {
            enable = true;
            ports = [
              "${config.mine.base.networking.meta.tailscaleIp}:443:8443"
              "${config.mine.base.networking.meta.hostIp}:443:443"
              "${config.mine.base.networking.meta.hostIp}:8082:8082"
            ];
            extraCmds = [
              "--accesslog=true"
              "--entrypoints.tailscale.address=:8443"
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
          };
        };

        services = {
          backups = enabled;
          ddns = enabled;
        };
      };
    };
}
