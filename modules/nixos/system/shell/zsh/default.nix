{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.shell.zsh;

in {
  options.mine.system.shell.zsh = {
    enable = mkEnableOption "zsh";
  };

  config = mkIf cfg.enable {
    programs.zsh.enable = true;
  };
}
