{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.home-manager.zsh;
  aliases = import ../../../../shared/aliases.nix;

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

        shellAliases =
          aliases.systemctl // aliases.eza // lib.optionals config.mine.services.docker.enable aliases.docker;

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
