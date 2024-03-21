{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.syncthing;
  user = config.mine.user;

in {
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
