{ lib, config, ... }:
let

  inherit (lib) mkIf types;
  inherit (lib.thurs) mkOpt;
  inherit (config.mine) user;
  cfg = config.mine.home.alacritty;

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
