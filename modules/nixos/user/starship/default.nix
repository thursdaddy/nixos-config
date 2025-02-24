{ lib, config, ... }:
let

  inherit (lib) mkIf;
  cfg = config.mine.user.shell.starship;
  langs = "$aws$python$terraform$vagrant";

in
{
  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = {
        command_timeout = 5000;
        format = ''
          $os$directory $nix_shell$git_branch $git_status
          $character
        '';
        right_format = ''
          ${langs}$direnv$cmd_duration$username$hostname$time
        '';
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };

        direnv = {
          disabled = false;
          format = "[ $symbol$loaded$denied  ]($style)";
          style = "fg:#FF8700";
          symbol = " ";
          allowed_msg = "";
          loaded_msg = "";
          not_allowed_msg = "";
          denied_msg = "";
          unloaded_msg = "";
        };

        python = {
          disabled = false;
          format = "[ $symbol$pyenv_prefix($version)($virtualenv) ]($style)";
          symbol = " ";
          style = "fg:#81A2BE";
        };

        aws = {
          disabled = false;
          format = "[ $symbol($profile)$region ]($style)";
          symbol = "  ";
          style = "fg:#81A2BE";
        };

        vagrant = {
          disabled = false;
          format = "[ $symbol($version) ]($style)";
          symbol = " ";
          style = "fg:#81A2BE";
        };

        terraform = {
          disabled = false;
          format = "[ $symbol($workspace) ]($style)";
          symbol = " ";
          style = "fg:#81A2BE";
        };

        os = {
          disabled = false;
          symbols = {
            NixOS = " ";
            Macos = " ";
          };
        };

        status = {
          style = "italic";
          disabled = false;
          symbol = "[](fg:#D54E53)";
          success_symbol = "[](fg:#A7AF63)";
          format = "[$int]($style)";
        };

        sudo = {
          disabled = true;
          format = "[$symbol]($style)";
          style = "red";
          symbol = "󰀨 ";
        };

        username = {
          show_always = true;
          style_user = "fg:#A7AF63";
          style_root = "bold fg:#D54E53";
          format = "[$user]($style)";
        };

        hostname = {
          ssh_only = false;
          style = "fg:#A7AF63";
          format = "[@$hostname]($style)";
        };

        cmd_duration = {
          disabled = false;
          format = "[  $duration  ]($style)";
          style = "fg:#F0C674";
        };

        nix_shell = {
          disabled = false;
          style = "fg:#FFD687";
          symbol = " ";
          format = "[$symbol$state ]($style)";
        };

        git_branch = {
          symbol = " ";
          style = "fg:#A7AF63";
          format = "[$symbol$branch]($style)";
        };

        git_status = {
          disabled = false;
          style = "fg:#F0C674";
          format = "[($stashed$deleted$renamed$modified$staged$untracked$ahead_behind)]($style)";
          staged = "+$count ";
          modified = "!$count ";
          deleted = "[✘$count ](fg:#D54E53)";
          stashed = "[*$count ](fg:#A8AF63)";
          renamed = "[$count ](fg:#Ff8700)";
          untracked = "[?$count ](fg:#81A2BE)";
          ahead = "[⇡$count ](fg:#A7AF63)";
          behind = "[⇣$count ](fg:#FF8700)";
          diverged = "⇕ ⇡$ahead_count ⇣$behind_count ";
        };

        directory = {
          format = "[ $path]($style)";
          style = "fg:#81A2BE";
          truncate_to_repo = false;
          truncation_length = 5;
          truncation_symbol = "…/";
        };

        time = {
          disabled = false;
          time_format = "%R:%S";
          style = "fg:#81A2BE";
          format = "[    $time]($style)";
        };
      };
    };
  };
}
