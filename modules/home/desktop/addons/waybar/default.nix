{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.desktop.waybar;
  user = config.mine.user;

in {
  options.mine.desktop.waybar = {
    enable = mkEnableOption "Enable waybar";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.waybar = {
        enable = true;

      style = ./themes/nord/style.css;

      settings = [
        {
          name = "main";
          output = [ "DP-2" "!DP-1" "!DP-3" ];
          layer = "top";
          position = "bottom";
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right =
            [ "pulseaudio" "cpu" "memory" "temperature" "clock" "tray" ];
          clock.format = "{:%Y-%m-%d %H:%M}";
          "hyprland/workspaces" = {
            active-only = false;
            all-outputs = false;
            persistent-workspaces = {
              "DP-2" = [ 1 2 3 4 ];
            };
          };
        }
        {
          name = "top";
          output = [ "!DP-2" "DP-1" "!DP-3" ];
          layer = "top";
          position = "bottom";
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right =
            [ "pulseaudio" "cpu" "memory" "temperature" "clock" "tray" ];
          clock.format = "{:%Y-%m-%d %H:%M}";
          "hyprland/workspaces" = {
            active-only = false;
            all-outputs = false;
            persistent-workspaces = {
              "DP-1" = [ 8 9 10 ];
            };
          };
        }
        {
          name = "side";
          output = [ "!DP-2" "!DP-1" "DP-3" ];
          layer = "top";
          position = "bottom";
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right =
            [ "pulseaudio" "cpu" "memory" "temperature" "clock" "tray" ];
          clock.format = "{:%Y-%m-%d %H:%M}";
          "hyprland/workspaces" = {
            active-only = false;
            all-outputs = false;
            persistent-workspaces = {
              "DP-3" = [ 5 6 7 ];
            };
          };
        }
        ];
      };

      systemd.user.services.waybar = {
        Unit = {
          Description =
            "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "graphical-session.target" "desktop.service" ];
          After = [ "graphical-session-pre.target" ];
        };

        Service = {
          ExecStart = "${pkgs.waybar}/bin/waybar";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
