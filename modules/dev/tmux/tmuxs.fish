# Set FZF colors to match Gruvbox Dark theme
set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS "\
"--color=fg:#ebdbb2,bg:-1,hl:#fabd2f "\
"--color=fg+:#ebdbb2,bg+:#3c3836,hl+:#fabd2f "\
"--color=info:#83a598,prompt:#b8bb26,pointer:#fe8019 "\
"--color=marker:#fe8019,spinner:#fe8019,header:#83a598"

# Ensure thurs session exists with ferrosonic and notes window
for app in thurs
  if not tmux has-session -t $app 2>/dev/null
    set -l cols (tput cols 2>/dev/null; or echo 200)
    set -l lines (tput lines 2>/dev/null; or echo 50)
    tmux new-session -d -x "$cols" -y "$lines" -s $app -n ferrosonic "fish -c 'while test -z \"\$(tmux list-clients -t $app 2>/dev/null)\"; sleep 0.5; end; clear; echo \"Launching Ferrosonic...\"; while not ferrosonic; echo \"ferrosonic crashed. Restarting in 2 seconds...\"; sleep 2; end'"\; new-window -c "$HOME/notes/obsidian/thurs" -n notes
  end
end

# start tmux session after cd'ing into the dir
function tmux_session_start
  cd $argv
  # Sanitize session name by replacing invalid characters (. and :) with hyphens
  set SESSION (basename "$PWD" | string replace -a '.' '-' | string replace -a ':' '-')

  # create a new session with 2 windows, one being nvim in focus when attached
  tmux new-session -d -s "$SESSION" -n nvim 'nvim'\; \
       new-window\; \
       select-window -t :nvim

  # Context-aware attach: use switch-client if already inside tmux
  if set -q TMUX
    tmux switch-client -t "$SESSION"
  else
    tmux attach -t "$SESSION"
  end
end

# flat selector to list and jump to any window across all sessions
function tmux_window_jumper
  set -l windows (tmux list-windows -a -F '#{session_name}:#{window_index}	#{session_name} ➜ #{window_name}   (#{pane_current_command})')
  set -l selected (printf "%s\n" $windows | fzf --delimiter '\t' --with-nth 2 --prompt="󰖲  " --preview 'tmux capture-pane -ep -t {1}')

  if test -n "$selected"
    set -l parts (string split \t $selected)
    set -l target_window $parts[1]
    if set -q TMUX
      tmux switch-client -t "$target_window"
    else
      set -l target_session (string split : $target_window)[1]
      tmux attach -t "$target_session" \; select-window -t "$target_window"
    end
  end
end

# select or create new tmux session
function tmux_session_selector
  if tmux list-sessions 2>/dev/null
    set fzf_options "new-session" "running-sessions" "kill-session"
  else
    set fzf_options "new-session"
  end

  set FZF_PROMPT (printf "%s\n" $fzf_options | fzf --prompt="  ")

  switch "$FZF_PROMPT"
    case running-sessions
      set sessions (tmux list-sessions -F '#{session_name}')
      set selected_session (printf "%s\n" $sessions | fzf --prompt="󰖰  " --preview 'tmux list-windows -t {} -F "#I:#W #{?window_active,(active),}" && echo "" && echo "=== Active Pane Preview ===" && tmux capture-pane -ep -t {}') || exit

      if set -q TMUX
        tmux switch-client -t "$selected_session"
      else
        tmux attach -t "$selected_session"
      end

    case kill-session
      set sessions (tmux list-sessions -F '#{session_name}')
      set selected_session (printf "%s\n" $sessions | fzf --prompt="󰆴  " --preview 'tmux list-windows -t {} -F "#I:#W #{?window_active,(active),}" && echo "" && echo "=== Active Pane Preview ===" && tmux capture-pane -ep -t {}') || exit
      tmux kill-session -t "$selected_session"

    case new-session
      # Filter paths that actually exist to prevent find errors
      set existing_paths
      for p in $tmuxs_paths
        if test -d "$p"
          set existing_paths $existing_paths "$p"
        end
      end

      set dirs
      if set -q existing_paths[1]
        set dirs (find $existing_paths -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
      end

      # Add zoxide directories if available
      if type -q zoxide
        for z_dir in (zoxide query -l 2>/dev/null)
          if not contains $z_dir $dirs; and test -d "$z_dir"
            set dirs $dirs $z_dir
          end
        end
      end

      set selected_dir (printf "%s\n" $dirs | fzf --prompt="  " --preview 'if [ -d {} ]; then (if [ -d {}/.git ] && command -v git >/dev/null; then echo "=== Git Status ==="; git -C {} status -s; echo ""; fi; echo "=== Content ==="; if command -v eza >/dev/null; then eza --tree --level=2 --color=always --icons {}; else ls -F {}; fi); fi') || exit
      set basename (basename "$selected_dir" | string replace -a '.' '-' | string replace -a ':' '-')

      # Use native tmux has-session to check existence
      if tmux has-session -t "$basename" 2>/dev/null
        if set -q TMUX
          tmux switch-client -t "$basename"
        else
          tmux attach -t "$basename"
        end
      else
        tmux_session_start "$selected_dir"
      end
  end
end

# check if arg is passed to tmuxs to enable bypassing fzf
if not set -q argv[1]
  tmux_session_selector
else
  # Check if the user requested the flat window jumper
  if test "$argv[1]" = "--windows" -o "$argv[1]" = "-w"
    tmux_window_jumper
  else
    # if arg is ., set pwd as path for tmux_session_start
    if string match -q "." "$argv"
      set path $PWD
    else
      # Filter existing paths
      set existing_paths
      for p in $tmuxs_paths
        if test -d "$p"
          set existing_paths $existing_paths "$p"
        end
      end
      if set -q existing_paths[1]
        set path (find $existing_paths -mindepth 1 -maxdepth 1 -type d -iname "$argv" 2>/dev/null | head -n1)
      else
        set path ""
      end

      # Fall back to zoxide query if directory not found in tmuxs_paths
      if test -z "$path"; and type -q zoxide
        set path (zoxide query "$argv" 2>/dev/null)
      end
    end

    if test -z "$path"
      echo "Directory not found, starting selector"
      tmux_session_selector
    else
      set basename (basename "$path" | string replace -a '.' '-' | string replace -a ':' '-')
      if tmux has-session -t "$basename" 2>/dev/null
        if set -q TMUX
          tmux switch-client -t "$basename"
        else
          tmux attach -t "$basename"
        end
      else
        tmux_session_start "$path"
      end
    end
  end
end
