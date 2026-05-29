_: {
  configurations.nixos.printpi.module =
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
            hostName = "printpi";
            meta = {
              hostIp = "192.168.10.185";
              tailscaleIp = "100.100.56.18";
            };
          };
        };

        containers = {
          gatus = {
            enable = true;
            endpointsFile = config.nixos-thurs.gatus.publicEndpoints;
            gotifyUrl = "https://gotify.${config.nixos-thurs.publicDomain}";
          };
          traefik = {
            enable = true;
            ports = [
              "${config.mine.base.networking.meta.hostIp}:8082:8082"
              "${config.mine.base.networking.meta.hostIp}:443:443"
              "${config.mine.base.networking.meta.tailscaleIp}:443:8443"
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
        };
      };
    };
}
