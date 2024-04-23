{ lib, config, pkgs, inputs, ... }:
with lib;
let

  cfg = config.mine.desktop.hyprpaper;

in
{
  options.mine.desktop.hyprpaper = {
    enable = mkEnableOption "Enable Hyprpaper";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      inputs.hyprpaper.packages.${pkgs.system}.hyprpaper
    ];

    systemd.user.services.hyprpaper = {
      description = "autostart service for Hyprpaper";
      documentation = [ "https://github.com/hyprwm/hyprpaper" ];
      after = [ "graphical-session.target" ];
      partOf = [ "desktop.service" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${lib.getExe inputs.hyprpaper.packages.${pkgs.system}.hyprpaper}";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        RestartSec = "2s";
        KillMode = "mixed";
      };
    };
  };
}
