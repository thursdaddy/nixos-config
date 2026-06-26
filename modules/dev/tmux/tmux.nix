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

      tmuxs_py = pkgs.writeScriptBin "tmuxs" ''
        #!${pkgs.python3}/bin/python3
        SEARCH_PATHS = ${builtins.toJSON cfg.sessionizer.searchPaths}
        ${builtins.replaceStrings [ "SEARCH_PATHS = []" ] [ "" ] (builtins.readFile ./tmuxs.py)}
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
            };
          };
        };
      };

      config = {
        environment.systemPackages = [
          (lib.mkIf cfg.sessionizer.enable tmuxs_py)
          pkgs.tmux
          pkgs.fzf
          pkgs.gitmux
        ] ++ lib.optionals cfg.sessionizer.enable [ pkgs.zoxide ];

        programs.tmux = {
          enable = true;
          extraConfig =
            let
              tmuxConf = builtins.readFile ./tmux.conf;
            in
            ''
              ${builtins.replaceStrings
                [ "@fzf@" "@yank@" ]
                [ "${pkgs.tmuxPlugins.tmux-fzf}" "${pkgs.tmuxPlugins.yank}" ]
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
