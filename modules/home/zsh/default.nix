{ pkgs, home-manager, ... }: {

  home.packages = with pkgs; [ zsh ];

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;

    shellAliases = {
      ll = "ls -larth";
      db = "docker build -t $(whoami)/$(basename $(pwd)):dev .";
      dbnc = "docker build --no-cache -t $(whoami)/$(basename $(pwd)):dev .";
      dr = "docker run -it --rm --name $(basename $(pwd)) $(whoami)/$(basename $(pwd)):dev bash";
      drs = "docker run -it --rm --name $(basename $(pwd)) $(whoami)/$(basename $(pwd)):dev sh";
    };

    oh-my-zsh = {
      enable = true;
      plugins = ["man" "history-substring-search" "history" ];
      theme = "agnoster";
    };

  };

}
