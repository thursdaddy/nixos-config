{ lib, config, inputs, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  inherit (inputs.self.packages.${pkgs.system}) wallpapers;
  cfg = config.mine.desktop.hyprlock;

in
{
  options.mine.desktop.hyprlock = {
    enable = mkEnableOption "Enable hyprlock";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            grace = 3;
            ignore_empty_input = true;
          };

          background = [{
            path = "${wallpapers}/blue_astronaut_in_space.png";
          }];

          input-field = [{
            size = "300, 60";
            outline_thickness = 2;
            monitor = "";
            dots_size = 0.05;
            dots_spacing = 0.05;
            dots_center = true;
            outer_color = "rgba(0, 0, 0, 0)";
            inner_color = "rgba(0, 0, 0, 0.5)";
            font_color = "rgb(200, 200, 200)";
            fade_on_empty = true;
            fade_timeout = 5000;
            placeholder_text = "PASSWORD";
            position = "0, -120";
          }];

          label = {
            monitor = "";
            text = ''cmd[update:10] echo "<b>$(date +'%_I:%M:%S')</b>"'';
            text_align = "center";
            color = "rgba(255, 255, 255, 1.0)";
            font_size = "80";
            font_family = "Hack Nerd Fonts";
            position = "0, 80";
            halign = "center";
            valign = "center";
          };
        };
      };
    };
  };
}
