{ lib, config, ... }:
let

  inherit (lib) mkEnableOption;
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
