{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (lib.thurs) mkOpt;
  inherit (config.mine) user;
  cfg = config.mine.home-manager.tmux;

  tmuxs_paths = builtins.concatStringsSep " " cfg.sessionizer.searchPaths;
  tmuxs_fish = pkgs.writers.writeFishBin "tmuxs" ''
    set tmuxs_paths ${tmuxs_paths}
    ${builtins.readFile ./tmuxs.fish}
  '';
  tmuxs_zsh = pkgs.writeShellScriptBin "tmuxs" ''
    # tmuxs, like tmux + sessions

    if [ -z "$1" ]; then
      SESSION=$(basename $PWD)
    else
      SESSION=$1
    fi

    tmux has-session -t $1 2>/dev/null

    if [ $? != 0 ]; then
      echo "tmux session $1 does not exist!"
      path=$(find ${tmuxs_paths} -depth -maxdepth 1 -type d -name $1 -print -quit 2>&1)
      cd $path
      tmux new-session -d -s "$SESSION" -n nvim 'nvim' \; \
        new-window -n zsh \; \
        select-window -t :nvim\;
      tmux attach-session -t $SESSION
    else
      tmux attach-session -t $SESSION
    fi
  '';

in
{
  options.mine.home-manager.tmux = {
    enable = mkEnableOption "Enable tmux";
    sessionizer = mkOption {
      default = { };
      description = "Tmux-sessionizer script";
      type = types.submodule {
        options = {
          enable = mkOpt types.bool false "Enable tmuxs";
          searchPaths = mkOpt (types.listOf types.str) [ ] "Paths to use for autocomplete";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [
        (mkIf (cfg.sessionizer.enable && user.shell.package == pkgs.fish) tmuxs_fish)
        (mkIf (cfg.sessionizer.enable && user.shell.package == pkgs.zsh) tmuxs_zsh)
        tmux
      ];

      programs.tmux = {
        enable = true;
        prefix = "C-a";
        keyMode = "vi";

        mouse = true;
        newSession = true;
        customPaneNavigationAndResize = true;

        escapeTime = 0;
        baseIndex = 1;
        historyLimit = 20000;
        terminal = "xterm-256color";
        plugins = with pkgs; [
          tmuxPlugins.vim-tmux-navigator
          tmuxPlugins.tmux-fzf
          tmuxPlugins.copy-toolkit
          tmuxPlugins.yank
        ];
        extraConfig = ''
          TMUX_FZF_LAUNCH_KEY="C-space"
          bind | split-window -h -c "#{pane_current_path}"
          bind _ split-window -v -c "#{pane_current_path}"

          bind x kill-pane
          bind X kill-window

          set-window-option -g allow-rename off

          # Rename session and window
          bind r command-prompt -I "#{window_name}" "rename-window '%%'"
          bind R command-prompt -I "#{session_name}" "rename-session '%%'"

          # Edit configuration and reload
          bind C-e new-window -n 'tmux.conf' "sh -c 'nvim ~/.config/tmux/tmux.conf && tmux source ~/.config/tmux/tmux.conf && tmux display \"Config reloaded\"'"

          # Reload tmux configuration
          bind C-r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

          # Select pane and windows
          bind -r C-a last-window
          bind -r C-] next-window
          bind -r [ select-pane -t :.-
          bind -r ] select-pane -t :.+

          bind -r Tab switch-client -l

          bind -r o previous-window
          bind -r p next-window

          # TODO: nixify this
          # TOKYO DARK COLORS:
          BG_DARK="#1f2335"
          BG="#24283b"
          BG_HIGHLIGHT="#292e42"
          TERMINAL_BLACK="#414868"
          FG="#c0caf5"
          FG_DARK="#a9b1d6"
          FG_GUTTER="#3b4261"
          DARK3="#545c7e"
          COMMENT="#565f89"
          DARK5="#737aa2"
          BLUE0="#3d59a1"
          BLUE="#7aa2f7"
          CYAN="#7dcfff"
          BLUE1="#2ac3de"
          BLUE2="#0db9d7"
          BLUE5="#89ddff"
          BLUE6="#b4f9f8"
          BLUE7="#394b70"
          MAGENTA="#bb9af7"
          MAGENTA2="#ff007c"
          PURPLE="#9d7cd8"
          ORANGE="#ff9e64"
          YELLOW="#e0af68"
          GREEN="#9ece6a"
          GREEN1="#73daca"
          GREEN2="#41a6b5"
          TEAL="#1abc9c"
          RED="#f7768e"

          set-option -g automatic-rename on
          set-option -g automatic-rename-format '#{b:pane_current_command}'

          # riced tmux session picker
          bind-key Space choose-window -w -O name -F '#{?pane_format,#[fg=colour209]#{pane_current_command} #[fg=colour209]#{pane_title},#{?window_format,#[fg=colour209]#{window_name}#{window_flags}#{?#{==:#{window_panes},1}, #{?#{!=:#{window_name},#{pane_current_command}},#[fg=colour112]#{pane_current_command} ,}#[fg=colour39]#{pane_title},},#[fg=colour112]#{?session_grouped, (group #{session_group}: #{session_group_list}),}#{?session_attached,(attached),#[fg=colour9](unattached)}}}'

          set -g status-justify left

          set -g pane-border-style fg='#6272a4'
          set -g message-style bg="$BG_HIGHLIGHT",fg="$ORANGE"
          set -g status-style bg='#44475a',fg='#bd93f9'
          set -g status-interval 1

          set -g window-status-current-format "#[fg=$MAGENTA]      #I#[fg=$BLUE1] ❘#[fg=$GREEN]#W#[fg=$BLUE1]★  "
          set -g window-status-format "#[fg=$FG_DARK]      #I ❘#W  "

          set -g status-left-length 100
          set -g status-left "#[fg=$BG]#[bg=$BLUE5]#{?client_prefix,#[bg=$GREEN],}  "
          set -ga status-left "#[fg=$FG]#[bg=$BG_DARK]  #S  "

          set -g status-right-length 500
          set -g status-right "#[fg=$BLUE5]#(hostname -s) #[fg=$BG]#[bg=$BLUE5]   #(git rev-parse --abbrev-ref HEAD) "
          set -ga status-right " #[bg=$BG_DARK]#[fg=$MAGENTA] %a #[bg=$BG_DARK]#[fg=$FG_DARK] %b %d #[fg=$TEAL] #[fg=$GREEN]%l:%M:%S "

          set -g mode-style "fg=$FG_DARK,bg=$TERMINAL_BLACK"
        '';
      };

      home.file = mkIf (cfg.sessionizer.enable && user.shell.package == pkgs.zsh) {
        # requires oh-my-zsh to be enabled
        "${user.homeDir}/.local/bin/tmuxs_autocomplete.sh" = {
          text = ''
            #!/usr/bin/env bash
            _tmuxs_autocomplete() {
              local cur="''${COMP_WORDS[COMP_CWORD]}"
              local prev="''${COMP_WORDS[COMP_CWORD-1]}"
              local dir=$(find ${tmuxs_paths} -maxdepth 1 -mindepth 1 -type d -not -path '*/.*')
              if [[ $prev == "tmuxs" ]]; then
                COMPREPLY=($(compgen -W "$(basename -a $dir)" -- "$cur"))
              fi
            }
            complete -F _tmuxs_autocomplete tmuxs
          '';
        };
      };

      # source the autocomplete script in zsh
      programs.zsh = mkIf (cfg.sessionizer.enable && user.shell.package == pkgs.zsh) {
        initExtra = ''
          source ~/.local/bin/tmuxs_autocomplete.sh
        '';
      };
    };
  };
}
