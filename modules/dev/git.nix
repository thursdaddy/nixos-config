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

        [include]
          path = ${config.sops.templates."gitconfig-work-include".path}
      '';
    in
    {
      environment = {
        etc = {
          "gitconfig".text = myGitConfig;
        };
      };

      mine.dev.packages = with pkgs; [
        gh
        unstable.hunk
        gnupg
        pass
      ];

      programs = {
        fish = {
          shellAliases = lib.mkIf (user.shell.package == pkgs.fish) config.mine.aliases.git;
        };
      };

      sops = {
        secrets = {
          "work/ORG" = { };
          "work/USERNAME" = { };
          "work/EMAIL" = { };
        };
        templates = {
          "gitconfig-work-include" = {
            owner = "${user.name}";
            content = ''
              [includeIf "gitdir:~/dev/work/${config.sops.placeholder."work/ORG"}/"]
                path = ${config.sops.templates."gitconfig-work-profile".path}
            '';
          };
          "gitconfig-work-profile" = {
            owner = "${user.name}";
            content = ''
              [user]
                name = ${config.sops.placeholder."work/USERNAME"}
                email = ${config.sops.placeholder."work/EMAIL"}

              [core]
                sshCommand = ssh -F /dev/null -o IdentityFile=~/.ssh/${config.sops.placeholder."work/ORG"} -o IdentitiesOnly=yes -o AddKeysToAgent=yes
            '';
          };
        };
      };
    };
}
