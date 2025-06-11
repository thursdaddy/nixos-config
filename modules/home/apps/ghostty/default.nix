{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf mkForce;
  inherit (config.mine) user;
  cfg = config.mine.apps.ghostty;

in
{
  options.mine.home-manager.ghostty = {
    enable = mkEnableOption "Ghostty home-manager configs";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.ghostty = {
        enable = true;
        package = mkIf pkgs.stdenv.isDarwin pkgs.emptyDirectory; # ghostty is wip on darwin, installing via homebrew, hacky workaround to use home-manager for config
        settings = {
          confirm-close-surface = false;
          background-opacity = "0.95";
          window-theme = "system";

          gtk-titlebar = false;
          gtk-wide-tabs = true;
          gtk-adwaita = true;
          adw-toolbar-style = "raised-border";

          font-size = if pkgs.stdenv.isDarwin then "12" else "11";

          font-feature = [
            "-liga"
            "-calt"
            "-dlig"
          ];
          font-family = "\"JetBrains Mono NL\"";
        };
      };

      programs.tmux = {
        terminal = mkForce "xterm-ghostty";
      };
    };
  };
}
