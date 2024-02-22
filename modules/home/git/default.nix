{ lib, config, pkgs, username, ... }:
with lib;
let
  cfg = config.mine.git;

  in {
      options.mine.git = {
          enable = mkEnableOption "Git";
      };

      config = mkIf cfg.enable {
        home-manager.users.${username} = {
          home.packages = with pkgs; [ git gh ];

          programs.git = {
            enable = true;
            userName  = "thursdaddy";
            userEmail = "thursdaddy@pm.me";
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
