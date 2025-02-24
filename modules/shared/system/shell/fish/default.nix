{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.shell.fish;
  aliases = import ../../../../shared/aliases.nix;

in
{
  options.mine.system.shell.fish = {
    enable = mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fishPlugins.colored-man-pages
      fishPlugins.done
      fishPlugins.fzf-fish
      fishPlugins.forgit
      fishPlugins.grc
      grc
    ];

    programs.fish = {
      enable = true;
      shellAliases = aliases.eza
        // aliases.systemctl;
      promptInit = mkIf pkgs.stdenv.isDarwin "starship init fish | source";
      interactiveShellInit = ''
        set -U fish_greeting ""
        set -g fish_pager_color_prefix 444444

        bind \cx beginning-of-line
        bind \cb backward-word
        bind \cf forward-word
        bind \cy fish_clipboard_copy
        bind \cp fish_clipboard_paste

        function last_history_item
            echo sudo $history[1]
        end
        abbr -a !! --position anywhere --function last_history_item

        if test -d /opt/homebrew
          # Homebrew is installed on MacOS
          /opt/homebrew/bin/brew shellenv | source
        end
      '';
    };

    environment.pathsToLink = [ "/share/fish" ];
  };
}
