{ lib, config, ... }:
let

  inherit (lib) mkIf;
  cfg = config.mine.apps.chromium;

in
{
  config = mkIf cfg.enable {
    homebrew.casks = [ "chromium" ];
  };

}
