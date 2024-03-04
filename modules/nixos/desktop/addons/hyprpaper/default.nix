{ lib, config, pkgs, ... }:
with lib;
let

cfg = config.mine.nixos.hyprpaper;

in {
  options.mine.nixos.hyprpaper = {
    enable = mkEnableOption "hyprpaper";
  };

  config = mkIf cfg.enable {

    systemd.user.services.hyprpaper = {
      enable = true;
      description = "Hyprland wallpaper daemon";
      after = ["default.target"];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "3";
        ExecStart = "${lib.getExe pkgs.hyprpaper}";
      };
    };

    environment.systemPackages = with pkgs; [
      hyprpaper
    ];

  };
}
