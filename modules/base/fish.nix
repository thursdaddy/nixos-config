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

          # Zoxide integration
          if type -q zoxide
            zoxide init fish | source
          end

          # Gruvbox Dark fzf theme (with transparent bg for tmux popups)
          set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS "\
          "--color=fg:#ebdbb2,bg:-1,hl:#fabd2f "\
          "--color=fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f "\
          "--color=info:#83a598,prompt:#b8bb26,pointer:#fe8019 "\
          "--color=marker:#fe8019,spinner:#fe8019,header:#83a598"

          # Tmux integration: Highlight pane title in status bar when long command finishes
          if set -q TMUX
            function tmux_preexec --on-event fish_preexec
              if set -q tmux_pane_is_red
                tmux set-option -p -t "$TMUX_PANE" @pane_finished 0
                set -e tmux_pane_is_red
              end
            end
            function tmux_postexec --on-event fish_postexec
              # CMD_DURATION is in milliseconds (3000ms = 3 seconds)
              if set -q CMD_DURATION; and test "$CMD_DURATION" -gt 3000
                tmux set-option -p -t "$TMUX_PANE" @pane_finished 1
                set -g tmux_pane_is_red 1
                if set -q SSH_TTY
                  # Send the bell to the outer tmux session
                  printf "\a"
                  printf "\ePtmux;\a\e\\"
                end
              end
            end

            # Rename tmux window to the SSH hostname
            function ssh
              set -l host
              set -l skip_next 0
              for arg in $argv
                if test "$skip_next" -eq 1
                  set skip_next 0
                  continue
                end
                switch $arg
                  case '-b' '-c' '-D' '-E' '-e' '-F' '-I' '-i' '-J' '-L' '-l' '-m' '-O' '-o' '-p' '-R' '-S' '-w'
                    set skip_next 1
                  case '-*'
                    continue
                  case '*'
                    if not set -q host[1]
                      set host $arg
                    end
                end
              end

              if set -q host[1]
                set host (string split -r -m1 "@" $host)[-1]
                tmux rename-window "$host"
              end

              command ssh $argv

              if set -q host[1]
                tmux set-window-option automatic-rename on
              end
            end
          else if set -q SSH_TTY
            # If we are on a remote host via SSH, automatically ring the bell for long-running commands
            function tmux_remote_postexec --on-event fish_postexec
              if set -q CMD_DURATION; and test "$CMD_DURATION" -gt 3000
                printf "\a"
                printf "\ePtmux;\a\e\\"
              end
            end
          end
        '';
      };

      environment.pathsToLink = [ "/share/fish" ];
    };
}
