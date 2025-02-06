{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
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
