{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.hypridle;
  user = config.mine.user;
  notify-message = "notify-send \"$(date '+%A %I:%M:%S')\"";

in
{
  options.mine.desktop.hypridle = {
    enable = mkOpt types.bool false "Enable hypridle";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      imports = [ inputs.hypridle.homeManagerModules.hypridle ];

      services.hypridle = {
        enable = true;
        ignoreDbusInhibit = true;
        lockCmd = "pidof hyprlock || ${inputs.hyprlock.packages.${pkgs.system}.hyprlock}/bin/hyprlock";
        afterSleepCmd = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl dispatch dpms on";
        beforeSleepCmd = "loginctl lock-session";
        listeners = [
          {
            timeout = 600;
            onTimeout = "${notify-message} \"HyprIdle: Locking Screen...\" && loginctl lock-session";
            onResume = "${notify-message} \"HyprIdle: Screen Unlocked!\"";
          }
          {
            timeout = 900;
            onTimeout = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl dispatch dpms off";
            onResume = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl dispatch dpms on";

          }
          {
            timeout = 1500;
            onTimeout = "wall \"ATTENTION: SYSTEM WITH SUSPEND IN 5 MINUTES\"";
          }
          {
            timeout = 1740;
            onTimeout = "wall \"ATTENTION: SYSTEM WITH SUSPEND IN 1 MINUTE\"";
          }
          {
            timeout = 1800;
            onTimeout = "${notify-message} \"HyprIdle: Suspending system..\" && systemctl suspend";
          }
        ];
      };
    };
  };
}
