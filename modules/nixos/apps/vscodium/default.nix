{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.vscodium;

in
{
  options.mine.apps.vscodium = {
    enable = mkEnableOption "vscodium";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vscodium
    ];
  };
}
