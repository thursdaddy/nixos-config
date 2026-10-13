_: {
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.dev.tmux;
      inherit (config.mine.base) user;

      tmuxsSrc = builtins.readFile ./tmuxs.py;
      tmuxsPlaceholders = [ "@searchPaths@" "@remoteHosts@" ];
      tmuxs_py =
        assert lib.assertMsg (lib.all (p: lib.hasInfix p tmuxsSrc) tmuxsPlaceholders)
          "tmuxs.py is missing one of ${toString tmuxsPlaceholders}";
        pkgs.writeScriptBin "tmuxs" ''
          #!${pkgs.python3}/bin/python3
          ${builtins.replaceStrings tmuxsPlaceholders [
            (builtins.toJSON cfg.sessionizer.searchPaths)
            (builtins.toJSON cfg.sessionizer.remoteHosts)
          ] tmuxsSrc}
        '';

      gitmuxConf = pkgs.writeText "gitmux.conf" ''
        tmux:
          layout: [branch, divergence, " - ", flags]
          options:
            branch_max_len: 20
            branch_trim: right
            ellipsis: …
      '';
    in
    {
      options.mine.dev.tmux = {
        sessionizer = lib.mkOption {
          default = { };
          description = "Tmux-sessionizer script";
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "Enable tmuxs";
              searchPaths = lib.mkOption {
                type = lib.types.listOf lib.types.path;
                default = [ ];
                description = "Paths to use for autocomplete";
              };
              remoteHosts = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "SSH hosts queried for remote tmux sessions (merged with ~/.local/state/tmuxs/hosts.txt)";
              };
            };
          };
        };
      };

      config = {
        environment.systemPackages = [
          pkgs.tmux
          pkgs.fzf
          pkgs.gitmux
        ] ++ lib.optionals cfg.sessionizer.enable [ tmuxs_py pkgs.zoxide ];

        programs.tmux = {
          enable = true;
          extraConfig =
            let
              tmuxConf = builtins.readFile ./tmux.conf;
            in
            ''
              ${builtins.replaceStrings
                [ "@fzf@" "@yank@" "@gitmuxConf@" ]
                [ "${pkgs.tmuxPlugins.tmux-fzf}" "${pkgs.tmuxPlugins.yank}" "${gitmuxConf}" ]
                tmuxConf
              }

              set -g default-command "${pkgs.fish}/bin/fish"
            ''
            + (
              if pkgs.stdenv.isLinux then
                ''
                  bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
                  bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
                ''
              else if pkgs.stdenv.isDarwin then
                ''
                  bind-key -T copy-mode-vi 'y' send -X copy-pipe-and-cancel "pbcopy"
                  bind-key -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "pbcopy"
                ''
              else
                ""
            );
        };
      };
    };
}
