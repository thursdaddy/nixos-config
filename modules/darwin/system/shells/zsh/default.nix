{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.shells.zsh;

in {
  options.mine.system.shells.zsh = {
    enable = mkEnableOption "zsh";
  };

  config = mkIf cfg.enable {
    programs.zsh.enable = true;
  };
}
