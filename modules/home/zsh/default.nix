{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.home.zsh;
  user = config.mine.nixos.user;

  in {
    options.mine.home.zsh = {
      enable = mkEnableOption "zsh";
    };

    config = mkIf cfg.enable {

      programs.zsh.enable = true;
      home-manager.users.${user.name} = {

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
