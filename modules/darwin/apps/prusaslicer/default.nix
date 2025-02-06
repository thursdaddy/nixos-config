{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.prusa-slicer;

in
{
  options.mine.apps.prusa-slicer = {
    enable = mkEnableOption "Prusaslicer";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "prusaslicer" ];
  };
}
