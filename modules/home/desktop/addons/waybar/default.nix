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

#       settings = [{
#         layer = "bottom";
#         position = "bottom";
#         modules-left = [ "sway/workspaces" ];
#         modules-center = [ "sway/window" ];
#         modules-right =
#           [ "pulseaudio" "cpu" "memory" "temperature" "clock" "tray" ];
#         clock.format = "{:%Y-%m-%d %H:%M}";
#         "tray" = { spacing = 8; };
#         "cpu" = { format = "cpu {usage}"; };
#         "memory" = { format = "mem {}"; };
#         "temperature" = {
#           hwmon-path = "/sys/class/hwmon/hwmon1/temp2_input";
#           format = "tmp {temperatureC}C";
#         };
#         "pulseaudio" = {
#           format = "vol {volume} {format_source}";
#           format-bluetooth = "volb {volume} {format_source}";
#           format-bluetooth-muted = "volb {format_source}";
#           format-muted = "vol {format_source}";
#           format-source = "mic {volume}";
#           format-source-muted = "mic";
#         };
#       }];
      };
    };
  };
}

