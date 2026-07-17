_: {
  configurations.nixos.kepler.module =
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
        base.networking.hostName = "kepler";

        homelab.kepler = {
          hostIp = "192.168.10.68";
          tailscaleIp = "100.89.187.26";
        };

        containers = {
          settings.backend = "podman";
          gitea = enabled;
          grafana = enabled;
          traefik = {
            enable = true;
            dashboard = true;
            extraPorts = [
              "${config.mine.homelab.kepler.tailscaleIp}:443:8443"
              "${config.mine.homelab.kepler.hostIp}:443:443"
              "${config.mine.homelab.kepler.hostIp}:8082:8082"
            ];
          };
        };

        services = {
          backups = enabled;
          beszel-hub = enabled;
          loki = enabled;
          qemu-guest = enabled;
          victoriametrics = {
            enable = true;
            subDomain = "vm-infra";
            retentionPeriod = "2y";
          };
        };
      };
    };
}
