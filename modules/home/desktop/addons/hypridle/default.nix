{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.hypridle;
  user = config.mine.user;

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
        lockCmd = "pidof hyprlock || ${inputs.hyprlock.packages.${pkgs.system}.hyprlock}/bin/hyprlock";
        afterSleepCmd = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl dispatch dpms on";
        beforeSleepCmd = "loginctl lock-session";
        listeners = [
          {
            timeout = 30;
            onTimeout = "loginctl lock-session";
          }
          {
            timeout = 915;
            onTimeout = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl dispatch dpms off";
            onResume = "${inputs.hyprland.packages.${pkgs.system}.hyprland}/bin/hyprctl dispatch dpms on ";

          }
          {
            timeout = 1800;
            onTimeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
