{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.home.waybar;
  user = config.mine.nixos.user;

  in {
      options.mine.home.waybar = {
        enable = mkOpt types.bool true "Enable waybar";
      };

      config = mkIf cfg.enable {

        home-manager.users.${user.name} = {
            programs.waybar = {
                enable = true;
                systemd = {
                  enable = true;
                };
            };
        };
      };

}
