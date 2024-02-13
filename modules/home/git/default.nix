{ lib, config, pkgs, ... }: let
    inherit (lib) mkEnableOption mkIf;
    cfg = config.myopt.git;

    in {
        options.myopt.git = {
            enable = mkEnableOption "Git";
        };

        config = mkIf cfg.enable {
            home.packages = with pkgs; [ git ripgrep hub ];

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
