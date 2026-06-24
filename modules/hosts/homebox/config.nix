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
            wake-on-lan = {
              enable = true;
              interface = "eno1";
            };
          };
        };

        homelab.homebox = {
          hostIp = "192.168.10.60";
          tailscaleIp = "100.96.164.35";
        };

        services = {
          backups = enabled;
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
                };
              };
            };
          };
          sleep-on-lan = enabled;
          syncthing = {
            enable = true;
            folders = {
              "appd" = {
                path = "${user.homeDir}/appdaemon";
                devices = [
                  "mbp"
                  "c137"
                  "wormhole"
                ];
                ignorePerms = true;
              };
            };
          };
          traefik = enabled;
        };
      };
    };
}
