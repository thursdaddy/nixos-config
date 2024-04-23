{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.desktop.swaync;

in
{
  options.mine.desktop.swaync = {
    enable = mkEnableOption "Sway Notification Center";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      swaynotificationcenter
      libnotify
    ];
  };
}
