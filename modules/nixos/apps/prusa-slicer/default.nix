{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.prusa-slicer;

in
{
  options.mine.apps.prusa-slicer = {
    enable = mkEnableOption "prusa-slicer";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      prusa-slicer
    ];
  };
}
