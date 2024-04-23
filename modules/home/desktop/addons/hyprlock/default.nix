{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.hyprlock;
  user = config.mine.user;

in
{
  options.mine.desktop.hyprlock = {
    enable = mkOpt types.bool false "Enable hyprlock";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      imports = [
        inputs.hyprlock.homeManagerModules.hyprlock
      ];

      programs.hyprlock = {
        enable = true;
        package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;

        general.grace = 1;

        input-fields = [{
          size.width = 250;
          size.height = 60;
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgba(0, 0, 0, 0)";
          inner_color = "rgba(0, 0, 0, 0.5)";
          font_color = "rgb(200, 200, 200)";
          fade_on_empty = false;
          placeholder_text = "<i>Input Password...</i>";
          position.x = 0;
          position.y = -120;
        }];

        backgrounds = [{
          path = "$HOME/pictures/wallpapers/blue_astronaut_in_space.png";
        }];

        labels = [
          {
            text = ''cmd[update:100] echo "<b>$(date +'%_I:%M:%S')</b>"'';
            position = {
              x = 0;
              y = 30;
            };
            font_family = "Hack Nerd Fonts";
            font_size = 60;
            color = "rgba(255, 255, 255, 1.0)";
          }
        ];
      };
    };
  };
}
