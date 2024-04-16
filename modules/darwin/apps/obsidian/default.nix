{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.obsidian;

in
{
  options.mine.apps.obsidian = {
    enable = mkEnableOption "obsidian";
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "obsidian" ];
  };
}
