_: {
  configurations.nixos.netpi.module =
    {
      config,
      lib,
      hostName,
      hostIp,
      tailscaleIp,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
    in
    {

      mine = {
        base.networking = {
          inherit hostName;
        };

        homelab.${hostName} = {
          inherit hostIp;
          inherit tailscaleIp;
        };

        containers = {
          settings = {
            backend = "podman";
            autoPrune = false;
          };
        };

        services = {
          gitea-runner = {
            enable = true;
            runners = {
              "${config.networking.hostName}" = {
                labels = [
                  "runner:docker://gitea.thurs.pw/docker/gitea-runner:v0.2.3"
                ];
                settings = {
                  container = {
                    network = "gitea-runner-net";
                    options = "--dns=${config.mine.homelab.${config.networking.hostName}.hostIp}";
                  };
                  runner = {
                    capacity = 4;
                  };
                };
              };
            };
          };
          traefik = enabled;
          tailscale = {
            useRoutingFeatures = "server";
            extraUpFlags = [ "--advertise-routes=192.168.10.0/24" ];
          };
        };
      };
    };
}
