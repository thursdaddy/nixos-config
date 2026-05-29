_: {
  configurations.nixos.kepler.module =
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
            hostName = "kepler";
            meta = {
              hostIp = "192.168.10.68";
              tailscaleIp = "100.89.187.26";
            };
          };
        };

        containers = {
          gitea = enabled;
          grafana = enabled;
          prometheus = enabled;
          traefik = {
            enable = true;
            ports = [
              "${config.mine.base.networking.meta.tailscaleIp}:443:8443"
              "${config.mine.base.networking.meta.hostIp}:443:443"
            ];
            extraCmds = [
              "--api=true"
              "--entrypoints.tailscale.address=:8443"
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
        };

        services = {
          backups = enabled;
          beszel-hub = enabled;
          loki = enabled;
          qemu-guest = enabled;
        };
      };
    };
}
