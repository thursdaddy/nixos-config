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
          utils.sysadmin = enabled;
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
          hypridle = enabled;
          hyprland = enabled;
          hyprlock = enabled;
          hyprpaper = enabled;
          waybar = {
            enable = true;
            theme."mine" = enabled;
          };
          sddm = enabled;
        };

        apps = {
          chromium = enabled;
        };

        services = {
          backups = enabled;
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
