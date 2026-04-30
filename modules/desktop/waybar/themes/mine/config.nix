_: {
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.desktop.waybar.theme.mine or { };

      sharedModules = {
        "mpris" = {
          player = "Supersonic";
          format = "  {player_icon} {dynamic}";
          format-paused = "  {status_icon} <i>{dynamic}</i>";
          dynamic-order = [
            "artist"
            "album"
            "title"
          ];
          dynamic-len = 60;
          player-icons = {
            default = " ";
            Supersonic = "󰝚 ";
          };
          status-icons = {
            paused = " ";
            playing = " ";
            stopped = " ";
          };
          on-click = "${lib.getExe pkgs.playerctl} --player=Supersonic play-pause";
          on-click-right = "${lib.getExe pkgs.playerctl} --player=Supersonic next";
          on-click-middle = "${lib.getExe pkgs.playerctl} --player=Supersonic previous";
        };
        "hyprland/workspaces" = {
          format = "{name}"; # Strictly only the workspace name/number
          active-only = false;
          all-outputs = false;
          show-special = false;
          on-click = "activate";
        };
        "hyprland/window" = {
          all-outputs = false;
          max-length = 40;
        };
        "custom/weather" = {
          exec = "/run/current-system/sw/bin/waybar-weather";
          return-type = "json";
          interval = 900;
          on-click = "/run/current-system/sw/bin/waybar-weather --current";
          on-click-middle = "/run/current-system/sw/bin/waybar-weather --ha";
          on-click-right = "/run/current-system/sw/bin/waybar-weather --forecast";
        };
        "custom/notification" = {
          tooltip = false;
          format = "{icon}";
          format-icons = {
            none = "  ";
            notification = "<span foreground='red'><sup></sup></span> ";
            dnd-notification = " <span foreground='red'><sup></sup></span> ";
            dnd-none = "  ";
            inhibited-notification = " <span foreground='red'><sup></sup></span> ";
            inhibited-none = "  ";
            dnd-inhibited-notification = " <span foreground='red'><sup></sup></span> ";
            dnd-inhibited-none = "  ";
          };
          return-type = "json";
          exec-if = "which ${lib.getExe' pkgs.swaynotificationcenter "swaync-client"}";
          exec = "${lib.getExe' pkgs.swaynotificationcenter "swaync-client"} -swb";
          on-click = "${lib.getExe' pkgs.swaynotificationcenter "swaync-client"} -t -sw";
          on-click-right = "${lib.getExe' pkgs.swaynotificationcenter "swaync-client"} -d -sw";
          on-click-middle = "${lib.getExe' pkgs.swaynotificationcenter "swaync-client"} -C -sw";
          escape = true;
        };
        "pulseaudio" = {
          scroll-step = 5;
          format = "{icon}   {volume}%";
          format-bluetooth = "{icon} {volume}%  ";
          format-bluetooth-muted = "   {icon}";
          format-muted = " {volume}%";
          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-middle = "${lib.getExe' pkgs.wireplumber "wpctl"} set-volume @DEFAULT_AUDIO_SINK@ .85";
          on-click-right = "${lib.getExe pkgs.pavucontrol}";
        };
        "tray" = {
          icon-size = 17;
          spacing = 6;
        };
        "temperature" = {
          thermal-zone = 2;
          hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
          critical-threshold = 70;
          warning-threshold = 60;
          format-critical = "{temperatureC}°C  ";
          format-warning = "{temperatureC}°C  ";
          format = "{temperatureC}°C  ";
        };
        "cpu" = {
          format = "  {usage}% ";
          interval = 3;
        };
        "memory" = {
          format = "  {}% ";
          interval = 10;
        };
        "clock#time" = {
          format = "{:%I:%M:%S %p }";
          interval = 1;
        };
        "clock#date" = {
          format = "{:%a %m-%d  }";
          interval = 1;
        };
        "network" = {
          interval = 5;
          interface = "enp5s0";
          format = "↓{bandwidthDownBytes} ↑{bandwidthUpBytes}";
        };
      };

      universalLayout = {
        layer = "top";
        position = "bottom";
        exclusive = true;
        passthrough = false;

        modules-left = [
          "hyprland/workspaces"
          "clock#date"
          "custom/weather"
          "mpris"
        ];
        modules-center = [
          "clock#time"
          "custom/notification"
        ];
        modules-right = [
          "pulseaudio"
          "cpu"
          "temperature"
          "memory"
          "network"
          "tray"
        ];
      };

      main = universalLayout // {
        name = "main";
        output = [
          "DP-2"
          "!DP-1"
          "!DP-3"
        ];
        "hyprland/workspaces" = {
          persistent-workspaces = {
            "DP-2" = [
              1
              2
              3
              4
            ];
          };
        };
      };

      side = universalLayout // {
        name = "side";
        output = [
          "!DP-2"
          "!DP-1"
          "DP-3"
        ];
        "hyprland/workspaces" = {
          persistent-workspaces = {
            "DP-3" = [
              5
              6
              7
            ];
          };
        };
      };

      top = universalLayout // {
        name = "top";
        output = [
          "!DP-2"
          "DP-1"
          "!DP-3"
        ];
        "hyprland/workspaces" = {
          persistent-workspaces = {
            "DP-1" = [
              8
              9
              10
            ];
          };
        };
      };

      combinedConfig = [
        (sharedModules // main)
        (sharedModules // side)
        (sharedModules // top)
      ];

    in
    {
      config = lib.mkIf (cfg.enable or false) {
        environment.etc = {
          "waybar/config".text = builtins.toJSON combinedConfig;
          "waybar/style.css".text = builtins.readFile ./style.css;
        };
      };
    };
}
