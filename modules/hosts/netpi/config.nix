_: {
  configurations.nixos.netpi.module =
    {
      config,
      lib,
      hostName,
      hostIp,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
    in
    {

      mine = {
        base = {
          networking = {
            inherit hostName;
            meta = {
              inherit hostIp;
            };
          };
        };

        services = {
          docker = {
            enable = true;
            autoPrune = false;
          };
          gitea-runner = {
            enable = true;
            runners = {
              "${config.networking.hostName}" = {
                labels = [
                  "runner:docker://gitea.thurs.pw/docker/gitea-runner:v0.2.3"
                ];
                settings = {
                  runner = {
                    capacity = 4;
                  };
                  container = {
                    privileged = true;
                    volumes = [
                      "/var/run/docker.sock:/var/run/docker.sock"
                    ];
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
