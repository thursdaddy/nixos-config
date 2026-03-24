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
          traefik = enabled;
          sleep-on-lan = enabled;
        };
      };
    };
}
