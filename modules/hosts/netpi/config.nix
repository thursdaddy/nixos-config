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
          docker = enabled;
          gitea-runner = {
            enable = true;
            runners = {
              "${config.networking.hostName}-stable" = {
                labels = [
                  "ansible-stable:docker://gitea.thurs.pw/docker/ansible:v0.2.0"
                ];
                settings = {
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
