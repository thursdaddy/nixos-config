{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.myopt.git;

  in {
      options.myopt.git = {
          enable = mkEnableOption "Git";
      };

      config = mkIf cfg.enable {
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


}
