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

      # networking.firewall.allowedTCPPorts = [
      #   9999
      # ];

      mine = {
        base = {
          bluetooth = enabled;
          nix.ghToken = enabled;
          networking = {
            hostName = "c137";
            networkManager = enabled;
            wake-on-lan = {
              enable = true;
              interface = "enp5s0";
            };
          };
          utils.sysadmin = enabled;
        };

        homelab.c137 = {
          hostIp = "192.168.10.137";
          nfs-mounts = {
            enable = true;
            mounts = {
              "/mnt/backups" = {
                device = "192.168.10.12:/fast/backups/${config.networking.hostName}";
              };
              "/mnt/music" = {
                device = "192.168.10.12:/fast/music";
              };
            };
          };
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
          gitea-runner = {
            enable = true;
            runners = {
              ${config.networking.hostName} = {
                settings = {
                  runner = {
                    capacity = 10;
                  };
                  container = {
                    force_pull = true;
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
          syncthing = {
            enable = true;
            folders = {
              "dev-homelab" = {
                path = "${user.homeDir}/dev/homelab";
                devices = [
                  "mbp"
                  "wormhole"
                ];
                ignorePerms = true;
              };
              "dev-nix" = {
                path = "${user.homeDir}/dev/nix";
                devices = [
                  "mbp"
                  "wormhole"
                ];
                ignorePerms = true;
              };
              "dev-cloud" = {
                path = "${user.homeDir}/dev/cloud";
                devices = [
                  "mbp"
                  "wormhole"
                ];
                ignorePerms = true;
              };
              "notes" = {
                path = "${user.homeDir}/notes";
                devices = [
                  "mbp"
                  "pixel7-pro"
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
