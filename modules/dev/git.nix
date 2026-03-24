{ inputs, ... }:
{
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;

      # build from source > home-manager
      myGitConfig = ''
        [core]
          editor = nvim

        [user]
          name = ${user.name}
          email = ${user.email}

        [init]
          defaultBranch = main

        [pull]
          rebase = false

        [push]
          autoSetupRemote = true
          followTags = true

        [safe]
          directory = *

        [branch]
            sort = -committerdate

        [tag]
            sort = version:refname

        [column]
          ui = auto

        [diff "sopsdiffer"]
          textconv = sops -d
      '';
    in
    {
      environment = {
        etc = {
          "gitconfig".text = myGitConfig;
        };

        systemPackages = with pkgs; [
          gh
          (
            if pkgs.stdenv.hostPlatform.isDarwin then
              inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.darwinGit
            else
              pkgs.git
          )
        ];
      };

      programs = {
        fish = {
          shellAliases = lib.mkIf (user.shell.package == pkgs.fish) config.mine.aliases.git;
        };
      };
    };
}
