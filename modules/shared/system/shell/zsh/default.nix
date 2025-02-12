{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.shell.zsh;

in
{
  options.mine.system.shell.zsh = {
    enable = mkEnableOption "zsh shell";
  };

  config = mkIf cfg.enable {
    programs.zsh.enable = true;
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
