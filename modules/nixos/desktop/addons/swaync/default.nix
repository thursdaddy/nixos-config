{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
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
