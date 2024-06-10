{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.steam;

in
{
  options.mine.apps.steam = {
    enable = mkEnableOption "steam";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
  };
}
