_: {
  flake.modules.generic.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;

      langs = "$aws$python$terraform$vagrant";
      starshipConfig = {
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
          style = "fg:#fe8019";
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
          style = "fg:#83a598";
        };

        aws = {
          disabled = false;
          format = "[ $symbol($profile)$region ]($style)";
          symbol = "  ";
          style = "fg:#83a598";
        };

        vagrant = {
          disabled = false;
          format = "[ $symbol($version) ]($style)";
          symbol = " ";
          style = "fg:#83a598";
        };

        terraform = {
          disabled = false;
          format = "[ $symbol($workspace) ]($style)";
          symbol = " ";
          style = "fg:#83a598";
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
          symbol = "[](fg:#fb4934)";
          success_symbol = "[](fg:#b8bb26)";
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
          style_user = "fg:#b8bb26";
          style_root = "bold fg:#fb4934";
          format = "[$user]($style)";
        };

        hostname = {
          ssh_only = false;
          style = "fg:#b8bb26";
          format = "[@$hostname]($style)";
        };

        cmd_duration = {
          disabled = false;
          format = "[  $duration  ]($style)";
          style = "fg:#fabd2f";
        };

        nix_shell = {
          disabled = false;
          style = "fg:#fabd2f";
          symbol = " ";
          format = "[$symbol$state ]($style)";
        };

        git_branch = {
          symbol = " ";
          style = "fg:#b8bb26";
          format = "[$symbol$branch]($style)";
        };

        git_status = {
          disabled = false;
          style = "fg:#fabd2f";
          format = "[($stashed$deleted$renamed$modified$staged$untracked$ahead_behind)]($style)";
          staged = "+$count ";
          modified = "!$count ";
          deleted = "[✘$count ](fg:#fb4934)";
          stashed = "[*$count ](fg:#b8bb26)";
          renamed = "[$count ](fg:#fe8019)";
          untracked = "[?$count ](fg:#83a598)";
          ahead = "[⇡$count ](fg:#b8bb26)";
          behind = "[⇣$count ](fg:#fe8019)";
          diverged = "⇕ ⇡$ahead_count ⇣$behind_count ";
        };

        directory = {
          format = "[ $path]($style)";
          style = "fg:#83a598";
          truncate_to_repo = false;
          truncation_length = 5;
          truncation_symbol = "…/";
        };

        time = {
          disabled = false;
          time_format = "%R:%S";
          style = "fg:#83a598";
          format = "[    $time]($style)";
        };
      };

      tomlFormat = pkgs.formats.toml { };
    in
    {
      environment = {
        systemPackages = [ pkgs.starship ];
        etc = {
          "starship.toml".source = tomlFormat.generate "starship-toml" starshipConfig;
        };
        variables = {
          STARSHIP_CONFIG = "/etc/starship.toml";
        };
      };

      programs.fish = lib.mkIf (user.shell.package == pkgs.fish) {
        interactiveShellInit = ''
          starship init fish | source
        '';
      };
    };
}
