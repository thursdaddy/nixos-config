{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.cli-apps.tmux.sessionizer;
  user = config.mine.user;

in
{
  options.mine.cli-apps.tmux.sessionizer = {
    enable = mkEnableOption "Enable tmux-sessionizor";
    searchPaths = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config =
    let
      tmuxs_paths = builtins.concatStringsSep " " cfg.searchPaths;
    in
    mkIf cfg.enable {
      home-manager.users.${user.name} = {
        # autocomplete scripts to find the basenames of cfg.searchPaths for tmux sessionizer (tmuxs)
        home.file = {
          "${user.homeDir}/.local/bin/tmuxs_autocomplete.sh" = {
            text = ''
              #/usr/bin/env bash

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
        programs.zsh = {
          initExtra = ''
            source ~/.local/bin/tmuxs_autocomplete.sh
          '';
        };

        home.packages = with pkgs; [
          # shell script that uses autocomplete to create or attach to tmux sessions
          (writeShellScriptBin "tmuxs" ''
            #/usr/bin/env bash

            if [ -z "$1" ]; then
              exit 1
            fi

            tmux has-session -t $1 2>/dev/null

            if [ $? != 0 ]; then
              echo "tmux session $1 does not exist!"
              path=$(find ${tmuxs_paths} -type d -name $1 -print -quit 2>&1)
              cd $path
              tmux new-session -d -s "$1" -n nvim 'nvim' \; \
                new-window -n zsh \; \
                select-window -t :nvim\;
              tmux attach-session -t $1
            else
              tmux attach-session -t $1
            fi
          '')
        ];
      };
    };
}
