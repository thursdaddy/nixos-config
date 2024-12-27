{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.gimp;

in
{
  options.mine.apps.gimp = {
    enable = mkEnableOption "Install GIMP";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gimp
    ];
  };
}
