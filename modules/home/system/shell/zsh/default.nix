{ lib, config, pkgs, ... }:
with lib;
let

cfg = config.mine.system.shell.zsh;
user = config.mine.user;

in {
  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.zsh = {
        enable = true;
        enableAutosuggestions = true;

        initExtra = mkIf pkgs.stdenv.hostPlatform.isDarwin ''
          eval "$(/opt/homebrew/bin/brew shellenv)"
        '';

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
        };

        plugins = [
          {
            name = "powerlevel10k";
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          }
          {
            name = "powerlevel10k-config";
            src = ./p10k;
            file = "p10k.zsh";
          }
        ];
      };
    };
  };
}
