{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.chromium;

in
{
  config = mkIf cfg.enable {
    homebrew.casks = [ "chromium" ];
  };

}
