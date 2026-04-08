_: {
  flake.modules.nixos.apps =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      ghosttyExec = pkgs.writeShellApplication {
        name = "ghostty";
        runtimeInputs = [ pkgs.ghostty ];

        text = ''
          exec ghostty --config-file=${ghosttyConfig} "$@"
        '';
      };

      ghosttyConfig = pkgs.writeText "ghostty.config" ''
        term = "xterm-256color"

        # General Window Settings
        confirm-close-surface = false
        background-opacity = 0.95
        window-theme = system

        # Typography
        font-family = "Monaspace Neon"
        font-size = 11

        # Font Features
        font-feature = -liga
        font-feature = -calt
        font-feature = -dlig
      '';
    in
    {
      environment.systemPackages = [
        ghosttyExec
        pkgs.ghostty.terminfo
      ];

      programs.fish.interactiveShellInit = ''
        if set -q GHOSTTY_RESOURCES_DIR
          source "$GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish"
        end
      '';
    };

  flake.modules.darwin.apps = {
    # The pkg has never worked on darwin and I don't want to use home-manager just for the settings file.
    homebrew.casks = [ "ghostty" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Ghostty.app" ];
  };
}
