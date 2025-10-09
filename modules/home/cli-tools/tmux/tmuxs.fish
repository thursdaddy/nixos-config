
# start tmux session after cd'ing into the dir
function tmux_session_start
  cd $argv
  set SESSION (basename $PWD)

  # create a new session with 2 windows, one being nvim in focus when attached
  tmux new-session -d -s $SESSION -n nvim 'nvim'\; \
       new-window\; \
       select-window -t :nvim

  # tmux starts a window 0 when executing tmux new-session, i dont like it
  if tmux has -t 0 2&>/dev/null
    tmux kill-session -t 0
  end

  # attach to new custom session
  tmux attach -t $SESSION

end

# select or create new tmux session
function tmux_session_selector
  if tmux list-sessions 2&> /dev/null
    set fzf_options "new-session" "running-sessions"
  else
    set fzf_options "new-session"
  end

  set FZF_PROMPT (printf "%s\n" $fzf_options | fzf --prompt="")

  switch "$FZF_PROMPT"
    case running-sessions
      set sessions (tmux list-sessions | awk -F":" '{print $1}')
      set selected_session (printf "%s\n" $sessions | fzf --preview 'tmux list-windows -t {} -F \'#{window_index}:#{window_active} | #{window_name}   > #{pane_title}\'') || exit
      tmux attach -t $selected_session

    case new-session
      set dirs (find $tmuxs_paths -depth -maxdepth 1 -type d)
      set selected_dir (printf "%s\n" $dirs | fzf) || exit
      set basename (basename $selected_dir)
      if tmux has -t $basename 2&> /dev/null
        tmux attach -t $basename
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
    set -g path $PWD
  else
    set -g path (find $tmuxs_paths -depth -maxdepth 1 -type d -iname $argv | head -n1)
  end

  if test -z "$path"
    echo "Directory not found, starting selector"
    tmux_session_selector
  else
    set -g basename (basename $path)
    if tmux ls | awk -F':' '{print $1}' | grep -ow "$basename" 2&> /dev/null
        tmux attach -t $basename
    else
        tmux_session_start $path
    end
  end
end
