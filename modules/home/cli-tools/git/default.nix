{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.home-manager.git;
  aliases = import ../../../shared/aliases.nix;

in
{
  options.mine.home-manager.git = {
    enable = mkEnableOption "Git configs";
  };

  config = mkIf cfg.enable {
    mine.cli-tools.git.enable = true;

    home-manager.users.${user.name} = {
      home.packages = with pkgs; [ git gh ];
      programs.git = {
        enable = true;
        userName = "${user.name}";
        userEmail = "${user.email}";
        includes = [
          {
            path = "~/projects/nix/nixos-thurs/.gitconfig";
            condition = "gitdir:~/projects/nix/nixos-thurs/";
          }
        ];
        extraConfig = {
          init = { defaultBranch = "main"; };
          pull = { rebase = false; };
          push = { autoSetupRemote = true; };
          core = { editor = "nvim"; };
        };
      };
      programs.zsh.shellAliases = mkIf (config.mine.home-manager.zsh.enable || user.shell.package == pkgs.zsh || config.mine.system.shell.zsh.enable) aliases.git;
    };
  };
}
