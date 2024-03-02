{ lib, config, pkgs, ... }:
with lib;
let

cfg = config.mine.nixos.hyprpaper;

in {
  options.mine.nixos.hyprpaper = {
    enable = mkEnableOption "hyprpaper";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      hyprpaper
    ];
  };

}
