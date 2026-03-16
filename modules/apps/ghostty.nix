_: {
  flake.modules.homeManager.apps =
    {
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (osConfig.mine.base) user;
    in
    {
      programs.ghostty = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
        settings = {
          confirm-close-surface = false;
          background-opacity = "0.95";
          window-theme = "system";

          gtk-titlebar = false;
          gtk-wide-tabs = true;
          adw-toolbar-style = "raised-border";

          font-size = if pkgs.stdenv.isDarwin then "12" else "11";

          font-feature = [
            "-liga"
            "-calt"
            "-dlig"
          ];
          font-family = "\"Monaspace Neon\"";
        };
        enableFishIntegration = lib.mkIf (user.shell.package == pkgs.fish) true;
        enableZshIntegration = lib.mkIf (user.shell.package == pkgs.zsh) true;
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "ghostty" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Ghostty.app" ];
  };
}
