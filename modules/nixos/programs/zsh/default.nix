{ config,  pkgs, username, ... }:
{
  programs.zsh = {
    enable = true;
    shellAliases = {
      ll = "ls -larth";
    };
    # Your zsh config
    ohMyZsh = {
      enable = true;
      plugins = ["git" "man" "history-substring-search" "history" ];
      theme = "agnoster";
    };
  };

  programs.zsh.autosuggestions.enable = true;

}
