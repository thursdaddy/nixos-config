{ lib, config, ... }:
with lib;
let

cfg = config.mine.home.syncthing;
user = config.mine.user;

in {
  options.mine.home.syncthing = {
    enable = mkEnableOption "Enable Syncthing";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      services.syncthing = {
        enable = true;

        tray = {
          enable = true;
        };

      };
    };
  };

}
