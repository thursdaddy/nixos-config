{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.cli-tools.just;

in
{
  options.mine.cli-tools.just = {
    enable = mkEnableOption "Enable just, its like make but more straight forward";
  };

  config = mkIf cfg.enable {
    homebrew.brews = [ "just" ];
  };
}
