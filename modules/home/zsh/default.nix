{ inputs, username, lib, config, pkgs, ... }:
with lib;
let
  cfg = config.mine.zsh;

  in {
    options.mine.zsh = {
      enable = mkEnableOption "zsh";
    };

    config = mkIf cfg.enable {
      programs.zsh.enable = true;
      home-manager.users.${username} = {

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
      };
    };

}
