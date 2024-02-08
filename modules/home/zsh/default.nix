{ pkgs, home-manager, ... }: {

  home.packages = with pkgs; [ zsh ];

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    shellAliases = {
      ll = "ls -larth";

    };
    oh-my-zsh = {
      enable = true;
      plugins = ["man" "history-substring-search" "history" ];
      theme = "agnoster";
    };
  };

}
