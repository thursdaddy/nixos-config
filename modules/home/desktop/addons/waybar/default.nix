{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.desktop.waybar;
  user = config.mine.user;

  custom_modules = {
    "mpd" = {
      format = "  {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{stateIcon} {artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ";
      interval = "10";
      state-icons = {
        paused = "";
        playing = "";
      };
    };
    "hyprland/window" = {
      all-outputs = false;
      max-length = 40;
    };
    "custom/notification" = {
      tooltip = false;
      format = "{icon}";
      format-icons = {
        notification = " <span foreground='red'><sup></sup></span>";
        none = "  ";
        dnd-notification = "<span foreground='red'><sup></sup></span>";
        dnd-none = "  ";
        inhibited-notification = " <span foreground='red'><sup></sup></span>";
        inhibited-none = "  ";
        dnd-inhibited-notification = "  <span foreground='red'><sup></sup></span>";
        dnd-inhibited-none = "   ";
      };
      return-type = "json";
      exec-if = "which /run/current-system/sw/bin/swaync-client";
      exec = "/run/current-system/sw/bin/swaync-client -swb";
      on-click = "/run/current-system/sw/bin/swaync-client -t -sw";
      on-click-right = "/run/current-system/sw/bin/swaync-client -d -sw";
      escape = true;
    };
    "wireplumber" = {
      scroll-step = "5";
      format = "{icon}  {volume}%";
      format-bluetooth = "{icon} {volume}% ";
      format-bluetooth-muted = " {icon}";
      format-muted = " {volume}%";
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = [ "" "" "" ];
      };
      on-click = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0";
      on-click-middle = "wpctl set-volume @DEFAULT_AUDIO_SINK@ .85";
      on-click-right = "pavucontrol";
    };
    "tray" = {
      icon-size = 17;
      spacing = 5;
    };
    "cpu" = {
      format = " {usage}%";
      interval = 3;
    };
    "memory" = {
      format = "  {}%";
      interval = 10;
    };
    "clock" = {
      format = "{:%Y-%m-%d %I:%M:%S %p}";
      interval = 1;
    };
    "network" = {
      interval = 5;
      interface = "enp5s0";
      format = "    ↓{bandwidthDownBytes} ↑{bandwidthUpBytes}  ";
    };
  };

  main = {
    name = "main";
    output = [ "DP-2" "!DP-1" "!DP-3" ];
    layer = "top";
    position = "bottom";
    modules-left = [ "hyprland/workspaces" "hyprland/window" ];
    modules-center = [ "mpd" ];
    modules-right =
      [ "network" "cpu" "memory" "wireplumber" "clock" "custom/notification" "tray" ];
    "hyprland/workspaces" = {
      active-only = false;
      all-outputs = false;
      persistent-workspaces = {
        "DP-2" = [ 1 2 3 4 ];
      };
    };
  };

  side = {
    name = "side";
    output = [ "!DP-2" "!DP-1" "DP-3" ];
    layer = "top";
    position = "bottom";
    modules-left = [ "hyprland/workspaces" ];
    modules-center = [ ];
    modules-right =
      [ "clock" "custom/notification" "tray" ];
    "hyprland/workspaces" = {
      active-only = false;
      all-outputs = false;
      persistent-workspaces = {
        "DP-3" = [ 5 6 7 ];
      };
    };
  };

  top = {
    name = "top";
    output = [ "!DP-2" "DP-1" "!DP-3" ];
    layer = "top";
    position = "bottom";
    modules-left = [ "hyprland/workspaces" "network" ];
    modules-center = [ "mpd" ];
    modules-right = [ "cpu" "memory" "wireplumber" "clock" "custom/notification" "tray" ];
    "hyprland/workspaces" = {
      active-only = false;
      all-outputs = false;
      persistent-workspaces = {
        "DP-1" = [ 8 9 10 ];
      };
    };
  };

  main_bar = custom_modules // main;
  side_bar = custom_modules // side;
  top_bar = custom_modules // top;

in
{
  options.mine.desktop.waybar = {
    enable = mkEnableOption "Enable waybar";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {

      gtk.iconTheme = {
        package = pkgs.gnome.adwaita-icon-theme;
        name = "adwaita-icon-theme";
      };

      programs.waybar = {
        enable = true;
        style = ./themes/origincode/style.css;
        settings = [
          main_bar
          side_bar
          top_bar
        ];
      };

      systemd.user.services.waybar = {
        Unit = {
          Description = "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "hyprland-session.target" "desktop.service" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.waybar}/bin/waybar";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          RestartSec = "2s";
          KillMode = "mixed";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    };
  };
}
