# start tmux session after cd'ing into the dir
function tmux_session_start
  cd $argv
  set SESSION (basename $PWD)

  # create a new session with 2 windows, one being nvim in focus when attached
  tmux new-session -d -s $SESSION -n nvim 'nvim'\; \
       new-window\; \
       select-window -t :nvim

  # Context-aware attach: use switch-client if already inside tmux
  if set -q TMUX
    tmux switch-client -t $SESSION
  else
    tmux attach -t $SESSION
  end
end

# select or create new tmux session
function tmux_session_selector
  if tmux list-sessions 2>/dev/null
    set fzf_options "new-session" "running-sessions"
  else
    set fzf_options "new-session"
  end

  set FZF_PROMPT (printf "%s\n" $fzf_options | fzf --prompt="Select action: ")

  switch "$FZF_PROMPT"
    case running-sessions
      set sessions (tmux list-sessions -F '#{session_name}')
      set selected_session (printf "%s\n" $sessions | fzf --preview 'tmux list-windows -t {} -F \'#{window_index}:#{window_active} | #{window_name}   > #{pane_title}\'') || exit

      if set -q TMUX
        tmux switch-client -t $selected_session
      else
        tmux attach -t $selected_session
      end

    case new-session
      # Assuming $tmuxs_paths is defined globally in your fish config
      set dirs (find $tmuxs_paths -depth -maxdepth 1 -type d)
      set selected_dir (printf "%s\n" $dirs | fzf --prompt="Select project: ") || exit
      set basename (basename $selected_dir)

      # Use native tmux has-session to check existence
      if tmux has-session -t "$basename" 2>/dev/null
        if set -q TMUX
          tmux switch-client -t $basename
        else
          tmux attach -t $basename
        end
      else
        tmux_session_start $selected_dir
      end
  end
end

# check if arg is passed to tmuxs to enable bypassing fzf
if not count $argv > /dev/null
  tmux_session_selector
else
  # if arg is ., set pwd as path for tmux_session_start
  if string match -q "." $argv
    set path $PWD
  else
    set path (find $tmuxs_paths -depth -maxdepth 1 -type d -iname $argv | head -n1)
  end

  if test -z "$path"
    echo "Directory not found, starting selector"
    tmux_session_selector
  else
    set basename (basename $path)
    if tmux has-session -t "$basename" 2>/dev/null
      if set -q TMUX
        tmux switch-client -t $basename
      else
        tmux attach -t $basename
      end
    else
      tmux_session_start $path
    end
  end
end
