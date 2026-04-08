_: {
  configurations.nixos.c137.module =
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
          nix.ghToken = enabled;
          networking = {
            networkManager = enabled;
            hostName = "c137";
            meta = {
              hostIp = "192.168.10.137";
            };
            wake-on-lan = {
              enable = true;
              interface = "enp5s0";
            };
          };
          nfs-mounts = {
            enable = true;
            mounts = {
              "/mnt/backups" = {
                device = "192.168.10.12:/fast/backups/${config.networking.hostName}";
              };
            };
          };
          utils.sysadmin = enabled;
        };

        containers = {
          traefik = enabled;
          vaultwarden = enabled;
        };

        dev.tmux = {
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/projects/nix"
              "${user.homeDir}/projects/cloud"
              "${user.homeDir}/projects/homelab"
              "${user.homeDir}/projects/personal"
            ];
          };
        };

        desktop = {
          amd = enabled;
          cursor = enabled;
          greetd = enabled;
          hypridle = enabled;
          hyprland = enabled;
          hyprlock = enabled;
          hyprpaper = enabled;
          waybar = {
            enable = true;
            theme."mine" = enabled;
          };
        };

        apps = {
          chromium = enabled;
        };

        services = {
          backups = enabled;
          docker = enabled;
          gitea-runner = {
            enable = true;
            runners = {
              ${config.networking.hostName} = {
                settings = {
                  runner = {
                    capacity = 10;
                  };
                  container = {
                    privileged = true;
                    force_pull = true;
                    volumes = [
                      "/var/run/docker.sock:/var/run/docker.sock"
                    ];
                  };
                };
              };
            };
          };
          ollama = enabled;
          prometheus = {
            exporters = {
              node = enabled;
              smartctl = enabled;
              zfs = enabled;
            };
          };
          sleep-on-lan = enabled;
          syncthing = enabled;
        };
      };
    };
}
