_: {
  configurations.nixos.printpi.module =
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
        base.networking.hostName = "printpi";

        homelab.printpi = {
          hostIp = "192.168.10.185";
          tailscaleIp = "100.100.56.18";
        };

        containers = {
          settings.backend = "podman";

          traefik = {
            enable = true;
            dashboard = true;
          };
        };

        services = {
          backups = enabled;
        };
      };
    };
}
