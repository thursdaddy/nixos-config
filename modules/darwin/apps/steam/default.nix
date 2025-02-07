{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.steam;

in
{
  options.mine.apps.steam = {
    enable = mkEnableOption "Install Steam";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "steam" ];
  };
}
