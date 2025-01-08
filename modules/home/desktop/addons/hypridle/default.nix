{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.hypridle;
  inherit (config.mine) user;
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
        settings = {
          general = {
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
            ignore_dbus_inhibit = true;
            lock_cmd = "pidof hyprlock || hyprlock";
          };

          listener = [
            {
              timeout = 1200;
              on-timeout = "${notify-message} \"HyprIdle: Locking Screen...\" && loginctl lock-session";
              on-resume = "${notify-message} \"HyprIdle: Screen Unlocked!\"";
            }
            {
              timeout = 1500;
              on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
              on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";

            }
            {
              timeout = 2100;
              on-timeout = "wall \"ATTENTION: SYSTEM WITH SUSPEND IN 5 MINUTES\"";
            }
            {
              timeout = 2340;
              on-timeout = "wall \"ATTENTION: SYSTEM WITH SUSPEND IN 1 MINUTE\"";
            }
            {
              timeout = 2430;
              on-timeout = "${notify-message} \"HyprIdle: Suspending system..\" && systemctl suspend";
            }
          ];
        };
      };
    };
  };
}
