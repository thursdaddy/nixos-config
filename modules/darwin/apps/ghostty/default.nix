{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.ghostty;

in
{
  options.mine.apps.ghostty = {
    enable = mkEnableOption "Ghostty";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "ghostty" ];
  };
}
