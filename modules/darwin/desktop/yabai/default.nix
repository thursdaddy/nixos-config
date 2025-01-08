{ lib, config, ... }:
with lib;
let

  cfg = config.mine.desktop.yabai;

in
{
  options.mine.desktop.yabai = {
    enable = mkEnableOption "yabai";
  };

  config = mkIf cfg.enable {
    services = {
      yabai = {
        enable = true;
        enableScriptingAddition = true;
        extraConfig = ''
          yabai -m rule --add app='System Settings' manage=off
        '';
        config = {
          layout = "bsp";
          auto_balance = "on";
          window_placement = "second_child";

          # window border
          window_border = "on";
          window_border_width = 2;
          active_window_border_color = "0xff5c7e81";
          normal_window_border_color = "0xff505050";
          insert_window_border_color = "0xffd75f5f";

          # window paddixg
          top_padding = 5;
          bottom_padding = 5;
          left_padding = 5;
          right_padding = 5;
          window_gap = 5;
          window_opacity = "off";

          # mouse setting
          focus_follows_mouse = "autoraise";
          mouse_follows_focus = "on";
          mouse_modifier = "alt";
          mouse_action1 = "move"; # left click + drag
          mouse_action2 = "resize"; # righ click + drag
          mouse_drop_action = "swap";

          # integrate spacebar
          #external_bar        = "all:26";
        };
      };
    };
  };
}
