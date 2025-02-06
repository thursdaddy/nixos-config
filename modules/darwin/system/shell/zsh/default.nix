{ lib, config, ... }:
let

  inherit (lib) mkIf types;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.system.shell.zsh;

in
{
  options.mine.system.shell.zsh = {
    enable = mkOpt types.bool true "zsh";
  };

  config = mkIf cfg.enable {
    programs.zsh.enable = true;
  };
}

