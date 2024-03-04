{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.waybar;
user = config.mine.nixos.user;

in {
  options.mine.home.waybar = {
    enable = mkOpt types.bool false "Enable waybar";
  };

  config = mkIf cfg.enable {

    home-manager.users.${user.name} = {
      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
        };

      style = ./themes/nord/style.css;

      settings = {
        main = {
          output = [ "DP-2" "!DP-1" "!DP-3" ];
          layer = "top";
          position = "top";
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right =
            [ "pulseaudio" "cpu" "memory" "temperature" "clock" "tray" ];
          clock.format = "{:%Y-%m-%d %H:%M}";
          "hyprland/workspaces" = {
            active-only = false;
            all-outputs = true;
          };
        };
        top = {
          output = [ "!DP-2" "DP-1" "!DP-3" ];
          layer = "bottom";
          position = "bottom";
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right =
            [ "pulseaudio" "cpu" "memory" "temperature" "clock" "tray" ];
          clock.format = "{:%Y-%m-%d %H:%M}";
        };
        right = {
          output = [ "!DP-2" "!DP-1" "DP-3" ];
          layer = "bottom";
          position = "bottom";
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right =
            [ "pulseaudio" "cpu" "memory" "temperature" "clock" "tray" ];
          clock.format = "{:%Y-%m-%d %H:%M}";
        };
      };
      };
    };
  };
}

