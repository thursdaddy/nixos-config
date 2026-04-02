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
        base = {
          networking = {
            hostName = "kepler";
            meta = {
              hostIp = "192.168.10.68";
            };
          };
        };

        containers = {
          gitea = enabled;
          grafana = enabled;
          prometheus = enabled;
          traefik = enabled;
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
