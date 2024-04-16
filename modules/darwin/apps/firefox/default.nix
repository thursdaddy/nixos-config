{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.firefox;

in
{
  config = mkIf cfg.enable {
    homebrew.casks = [ "firefox" ];
  };

}
