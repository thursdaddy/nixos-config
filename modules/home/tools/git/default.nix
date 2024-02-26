{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.home.git;
  user = config.mine.nixos.user;

  in {
      options.mine.home.git = {
          enable = mkEnableOption "Git";
      };

      config = mkIf cfg.enable {
        home-manager.users.${user.name} = {
          home.packages = with pkgs; [ git gh ];

          programs.git = {
            enable = true;
            userName  = "${user.name}";
            userEmail = "${user.email}";
            extraConfig = {
              init = { defaultBranch = "main"; };
              pull = { rebase = false; };
              push = { autoSetupRemote = true; };
            };
          };

          programs.zsh.shellAliases = {
              "gst" = "git -P status";
              "gd" = "git -P diff";
              "gds" = "git -P diff --staged";
          };
        };
      };

}
