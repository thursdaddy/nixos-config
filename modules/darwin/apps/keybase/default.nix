{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.keybase;

in
{
  options.mine.apps.keybase = {
    enable = mkEnableOption "keybase";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "keybase" ];
  };

}
