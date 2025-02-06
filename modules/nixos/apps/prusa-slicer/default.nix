{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
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
