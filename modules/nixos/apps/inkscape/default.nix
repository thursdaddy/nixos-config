{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.inkscape;

in
{
  options.mine.apps.inkscape = {
    enable = mkEnableOption "Install Inkscape";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inkscape
    ];
  };
}
