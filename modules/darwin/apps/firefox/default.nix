{ lib, config, ... }:
let

  inherit (lib) mkIf;
  cfg = config.mine.apps.firefox;

in
{
  config = mkIf cfg.enable {
    homebrew.casks = [ "firefox" ];
  };

}
