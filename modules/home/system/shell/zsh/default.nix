{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.home-manager.zsh;

in
{
  options.mine.home-manager.zsh = {
    enable = mkEnableOption "Enable Zsh";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.zsh = {
        enable = true;
        # this is required for 'tmuxs' script as it provides the "complete" command ¯\_(ツ)_/¯
        oh-my-zsh.enable = true;

        syntaxHighlighting.enable = true;

        initExtra = mkIf pkgs.stdenv.hostPlatform.isDarwin ''
          eval "$(/opt/homebrew/bin/brew shellenv)"
        '';

        shellAliases = {
          db = "docker build -t $(whoami)/$(basename $(pwd)):dev .";
          dbnc = "docker build --no-cache -t $(whoami)/$(basename $(pwd)):dev .";
          dr = "docker run -it --rm --name $(basename $(pwd)) $(whoami)/$(basename $(pwd)):dev bash";
          drs = "docker run -it --rm --name $(basename $(pwd)) $(whoami)/$(basename $(pwd)):dev sh";
          _ds = "sudo systemctl status";
          _dstop = "sudo systemctl stop";
          _drestart = "sudo systemctl restart";
          _dstart = "sudo systemctl start";
          ll = "ls -larth";
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
