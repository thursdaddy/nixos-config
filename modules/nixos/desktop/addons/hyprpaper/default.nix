{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.desktop.hyprpaper;

in {
  config = mkIf cfg.enable {
    environment.systemPackages = [
      inputs.hyprpaper.packages.${pkgs.system}.hyprpaper
    ];

    systemd.user.services.hyprpaper = {
      bindsTo = ["graphical-session.target"];
      after = ["graphical-session-pre.target"];
      description = "autostart service for Hyprpaper";
      documentation = ["https://github.com/hyprwm/hyprpaper"];
      serviceConfig = {
        ExecStart = "${lib.getExe inputs.hyprpaper.packages.${pkgs.system}.hyprpaper}";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };
      wantedBy = [ "hyprland-session.target" ];
    };
  };
}
