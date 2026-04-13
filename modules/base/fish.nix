_: {
  flake.modules.generic.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        fishPlugins.colored-man-pages
        fishPlugins.done
        # fishPlugins.fzf-fish #i https://github.com/NixOS/nixpkgs/issues/410069
        fishPlugins.forgit
        fishPlugins.grc
        grc
      ];

      programs.fish = {
        enable = true;
        promptInit = lib.mkIf pkgs.stdenv.isDarwin "starship init fish | source";
        shellAliases = config.mine.aliases.eza // config.mine.aliases.systemctl;
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

          function fish_should_add_to_history
              string match -qr "^\s" -- $argv; and return 1
              string match -qr "^clear\$" -- $argv; and return 1
              return 0
          end

          if test -d /opt/homebrew
            # Homebrew is installed on MacOS
            /opt/homebrew/bin/brew shellenv | source
          end
          starship init fish | source

          # Tokyo Dark fzf theme (with transparent bg for tmux popups)
          set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS "\
          "--color=fg:#c0caf5,bg:-1,hl:#2ac3de "\
          "--color=fg+:#c0caf5,bg+:#292e42,hl+:#2ac3de "\
          "--color=info:#7aa2f7,prompt:#bb9af7,pointer:#bb9af7 "\
          "--color=marker:#9ece6a,spinner:#ff007c,header:#7aa2f7"
        '';
      };

      environment.pathsToLink = [ "/share/fish" ];
    };
}
