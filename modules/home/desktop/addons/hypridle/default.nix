{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.desktop.hypridle;

  notify-message = "notify-send \"$(date '+%A %I:%M:%S')\"";

in
{
  options.mine.desktop.hypridle = {
    enable = mkEnableOption "Enable hypridle";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      services.hypridle = {
        enable = true;
        package = pkgs.unstable.hypridle;
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
            lock_cmd = "pidof hyprlock || hyprlock";
          };

          listener = [
            {
              timeout = 1200;
              on-timeout = "loginctl lock-session";
              on-resume = "${notify-message} \"HyprIdle: Screen Unlocked!\"";
            }
            {
              timeout = 1230;
              on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
              on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
            }
            {
              timeout = 1800;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };
    };
  };
}
