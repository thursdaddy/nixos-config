{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
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
