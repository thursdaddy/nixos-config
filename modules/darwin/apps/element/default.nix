{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.element;

in
{
  options.mine.apps.element = {
    enable = mkEnableOption "Element desktop client for Matrix";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "element" ];
  };
}
