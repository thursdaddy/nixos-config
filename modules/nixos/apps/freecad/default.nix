{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.freecad;

in
{
  options.mine.apps.freecad = {
    enable = mkEnableOption "Freecad";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      freecad
    ];
  };
}
