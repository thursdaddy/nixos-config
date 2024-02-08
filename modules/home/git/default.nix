{ pkgs, ... }: {

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
      "gst" = "${pkgs.git}/bin/git -P status";
      "gd" = "${pkgs.git}/bin/git -P diff";
      "gds" = "${pkgs.git}/bin/git -P diff --staged";
  };

}
