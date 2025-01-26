{ lib, config, ... }:
with lib;
let

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
