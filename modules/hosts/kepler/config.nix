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
          crowdsec = enabled;
          gitea = enabled;
          grafana = enabled;
          netalertx = {
            enable = true;
            interface = "ens18";
            subnet = "192.168.10.0/24";
          };
          traefik = {
            enable = true;
            dashboard = true;
            enableCrowdsec = true;
            extraPorts = [
              "${config.mine.homelab.kepler.tailscaleIp}:443:8443"
              "${config.mine.homelab.kepler.hostIp}:443:443"
              "${config.mine.homelab.kepler.hostIp}:8082:8082"
            ];
            extraCmds = [
              "--accesslog=true"
              "--experimental.plugins.bouncer.modulename=github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
              "--experimental.plugins.bouncer.version=v1.6.0"
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
