{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.home.tmux;
  user = config.mine.nixos.user;

  in {
    options.mine.home.tmux = {
      enable = mkEnableOption "Enable tmux";
    };

    config = mkIf cfg.enable {

      home-manager.users.${user.name} = {
        home.packages = with pkgs; [ tmux ];

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
          terminal = "screen-256color";
          extraConfig = ''
            bind | split-window -h -c "#{pane_current_path}"
            bind _ split-window -v -c "#{pane_current_path}"

            bind x kill-pane
            bind X kill-window

            set -g set-titles on
            set -g set-titles-string "#I:#W"

            # Rename session and window
            bind r command-prompt -I "#{window_name}" "rename-window '%%'"
            bind R command-prompt -I "#{session_name}" "rename-session '%%'"

            # Edit configuration and reload
            bind C-e new-window -n 'tmux.conf' "sh -c 'nvim ~/.config/tmux/tmux.conf && tmux source ~/.config/tmux/tmux.conf && tmux display \"Config reloaded\"'"

            # Reload tmux configuration
            bind C-r source-file ~/.config/.tmux.conf \; display "Config reloaded"

            # Select pane and windows
            bind -r C-a last-window
            bind -r C-] next-window
            bind -r [ select-pane -t :.-
            bind -r ] select-pane -t :.+
            bind -r Tab previous-window   # cycle thru MRU tabs
            bind -r C-o swap-pane -D

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

            # CUSTOM THEME/LOOK
            bind-key Space choose-window -w -O name -F '#{?pane_format,#[fg=colour209]#{pane_current_command} #[fg=colour209]#{pane_title},#{?window_format,#[fg=colour209]#{window_name}#{window_flags}#{?#{==:#{window_panes},1}, #{?#{!=:#{window_name},#{pane_current_command}},#[fg=colour112]#{pane_current_command} ,}#[fg=colour39]#{pane_title},},#[fg=colour112]#{?session_grouped, (group #{session_group}: #{session_group_list}),}#{?session_attached,(attached),#[fg=colour9](unattached)}}}'

            set -g status-justify left

            set -g pane-border-style fg='#6272a4'
            set -g message-style bg="$BG_HIGHLIGHT",fg="$ORANGE"
            set -g status-style bg='#44475a',fg='#bd93f9'
            set -g status-interval 5

            set -g window-status-current-format "#[fg=$MAGENTA]      #I#[fg=$BLUE1]❘#[fg=$GREEN]#W#[fg=$BLUE1]★  "
            set -g window-status-format "#[fg=$FG_DARK]      #I❘#W  "

            set -g status-left-length 100
            set -g status-left "#[fg=$BG]#[bg=$BLUE5]#{?client_prefix,#[bg=$GREEN],}  "
            set -ga status-left "#[fg=$FG]#[bg=$BG_DARK]  #S  "

            set -g status-right " #[fg=$MAGENTA] %a #[fg=$TEAL]#[fg=$GREEN]%l:%M:%S #[bg=$BG_DARK]#[fg=$FG_DARK]  %m-%d-%Y "
            set -ga status-right "#[fg=$BG]#[bg=$BLUE5]   #(git rev-parse --abbrev-ref HEAD) "

            set -g mode-style "fg=$FG_DARK,bg=$TERMINAL_BLACK"
            '';
        };
      };

    };
  }
