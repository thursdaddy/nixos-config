{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.aldente;

in
{
  options.mine.apps.aldente = {
    enable = mkEnableOption "Install AlDente battery management";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "aldente" ];
  };
}
