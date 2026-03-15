_: {
  flake.modules.homeManager.apps =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.ghostty = {
        enable = true;
        # ghostty is wip on darwin, installing via homebrew, hacky workaround to use home-manager for config
        package = lib.mkIf pkgs.stdenv.isDarwin pkgs.emptyDirectory;
        settings = {
          confirm-close-surface = false;
          background-opacity = "0.95";
          window-theme = "system";

          gtk-titlebar = false;
          gtk-wide-tabs = true;
          # gtk-adwaita = true;
          adw-toolbar-style = "raised-border";

          font-size = if pkgs.stdenv.isDarwin then "12" else "11";

          font-feature = [
            "-liga"
            "-calt"
            "-dlig"
          ];
          font-family = "\"Monaspace Neon\"";
        };
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "ghostty" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Ghostty.app" ];
  };
}
