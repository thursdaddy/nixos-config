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
      imports = [
        inputs.hypridle.homeManagerModules.hypridle
      ];

      services.hypridle = {
        enable = true;
        lockCmd = "pidof hyprlock || /etc/profiles/per-user/thurs/bin/hyprlock";
        afterSleepCmd = "/etc/profiles/per-user/thurs/bin/hyprctl dispatch dpms on";
        beforeSleepCmd = "loginctl lock-session";
        listeners = [
          {
            timeout = 900;
            onTimeout = "loginctl lock-session";
          }
          {
            timeout = 915;
            onTimeout = "/etc/profiles/per-user/thurs/bin/hyprctl dispatch dpms off";
            onResume = "/etc/profiles/per-user/thurs/bin/hyprctl dispatch dpms on ";

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
