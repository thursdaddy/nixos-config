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

      tmuxs_paths = builtins.concatStringsSep " " cfg.sessionizer.searchPaths;
      tmuxs_fish = pkgs.writers.writeFishBin "tmuxs" ''
        set tmuxs_paths ${tmuxs_paths}
        ${builtins.readFile ./tmuxs.fish}
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
          (lib.mkIf (cfg.sessionizer.enable && user.shell.package == pkgs.fish) tmuxs_fish)
          pkgs.tmux
          pkgs.fzf
        ];

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
            '';
        };
      };
    };
}
