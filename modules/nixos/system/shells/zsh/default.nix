{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.zsh;

in {
  options.mine.nixos.zsh = {
    enable = mkOpt types.bool false "Enable Zsh and ohMyZsh";
  };
  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      autosuggestions = {
        enable = true;
      };

      shellAliases = {
        ll = "ls -larth";
      };

      ohMyZsh = {
        enable = true;
        plugins = ["man" "history-substring-search" "history" ];
        theme = "agnoster";
      };
    };
  };

}
