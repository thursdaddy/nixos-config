{ inputs, lib, ... }:
{
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Profile-only glue: carries the /etc files hosts get from their modules. Only
      # referenced from mine.dev.package, so it is never forced on hosts.
      # hiPrio so the wrappers win the buildEnv collision with plain tmux/git.
      tmux = lib.hiPrio (
        pkgs.symlinkJoin {
          name = "tmux";
          paths = [ pkgs.tmux ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/tmux --add-flags "-f ${config.environment.etc."tmux.conf".source}"
          '';
          meta.mainProgram = "tmux";
        }
      );

      git = lib.hiPrio (
        pkgs.symlinkJoin {
          name = "git";
          paths = [ pkgs.git ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/git --set-default GIT_CONFIG_SYSTEM ${config.environment.etc.gitconfig.source}
          '';
          meta.mainProgram = "git";
        }
      );

      direnvConfig = pkgs.linkFarm "dev-direnv-config" (
        lib.mapAttrsToList (n: v: {
          name = lib.removePrefix "direnv/" n;
          path = v.source;
        }) (lib.filterAttrs (n: _: lib.hasPrefix "direnv/" n) config.environment.etc)
      );
    in
    {
      options.mine.dev = {
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Packages installed by the dev module; shared by hosts and the dev profile";
        };
        package = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "The dev module as a single installable package (nix profile)";
        };
      };

      config = {
        mine.dev.packages = [
          pkgs.glow
          pkgs.nixfmt
          pkgs.nixpkgs-fmt
          pkgs.shellcheck
          pkgs.statix
        ];

        environment.systemPackages = config.mine.dev.packages;

        mine.dev.package = pkgs.buildEnv {
          name = "dev";
          paths =
            config.mine.base.packages
            ++ config.mine.dev.packages
            ++ [
              pkgs.fish
              tmux
              git
              config.programs.direnv.package
              config.programs.nixvim.build.package
              (pkgs.writeTextDir "share/fish/vendor_conf.d/00-dev-env.fish" ''
                set -gx DIRENV_CONFIG ${direnvConfig}
                set -gx GIT_CONFIG_SYSTEM ${config.environment.etc.gitconfig.source}
                set -gx STARSHIP_CONFIG ${config.environment.etc."starship.toml".source}
                set -gx EDITOR nvim
                set -gx VISUAL nvim
              '')
              (pkgs.writeTextDir "share/fish/vendor_conf.d/zz-dev-fish.fish" ''
                if status is-interactive
                  ${lib.concatLines (
                    lib.mapAttrsToList (k: v: "alias ${k} ${lib.escapeShellArg v}") config.programs.fish.shellAliases
                  )}
                  ${config.programs.fish.interactiveShellInit}
                end
              '')
            ];
        };
      };
    };

  perSystem =
    { pkgs, system, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.isLinux {
        dev =
          (inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit lib;
            };
            modules = [
              # generic.base, not nixos.base: the latter imports private nixos-thurs configs;
              # generic.base defines sops.* (needs sops-nix) and provides the overlays and mine.* options dev reads.
              inputs.sops-nix.nixosModules.sops
              inputs.self.modules.generic.base
              inputs.self.modules.nixos.dev
              {
                nixpkgs.hostPlatform = system;
                system.stateVersion = lib.trivial.release;
                mine.dev.agents.enable = false;
                mine.dev.tmux.sessionizer = {
                  enable = true;
                  searchPaths = [
                    "~/dev"
                    "~/dev/nix"
                  ];
                };
                programs.nixvim.plugins.obsidian.enable = lib.mkForce false;
              }
            ];
          }).config.mine.dev.package;
      };
    };
}
