{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.home.alacritty;
  inherit (config.mine) user;

in
{
  options.mine.home.alacritty = {
    enable = mkOpt types.bool false "Enable Alacritty";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {

      programs.alacritty = {
        enable = true;
        settings = {
          window.opacity = 0.9;
          cursor = {
            style = {
              shape = "Underline";
              blinking = "Always";
            };
            thickness = 0.20;
          };
          selection.save_to_clipboard = true;
          decorations = "none";
        };
      };
    };
  };
}
