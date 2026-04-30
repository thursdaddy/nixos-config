_: {
  configurations.nixos.homebox.module =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
      inherit (config.mine.base) user;
    in
    {
      mine = {
        base = {
          bluetooth = enabled;
          networking = {
            hostName = "homebox";
            meta = {
              hostIp = "192.168.10.60";
            };
            wake-on-lan = {
              enable = true;
              interface = "eno1";
            };
          };
        };

        dev = {
          tmux.sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/"
              "/var/lib/"
            ];
          };
        };

        services = {
          backups = enabled;
          docker = {
            enable = true;
            autoPrune = false;
          };
          gitea-runner = {
            enable = true;
            runners = {
              "${config.networking.hostName}" = {
                labels = [
                  "runner:docker://gitea.thurs.pw/docker/gitea-runner:v0.2.2"
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
          sleep-on-lan = enabled;
          traefik = enabled;
        };
      };
    };
}
