{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.apps.ghostty;
  inherit (config.mine) user;

in
{
  config = mkIf cfg.enable {
    nixpkgs.config.allowBroken = true;
    home-manager.users.${user.name} = {
      programs.ghostty = {
        enable = true;
        package = mkIf pkgs.stdenv.isDarwin pkgs.tree;
        settings = {
          confirm-close-surface = false;
          background-opacity = "0.95";
          window-theme = "system";

          gtk-titlebar = false;
          gtk-wide-tabs = true;
          gtk-adwaita = true;
          adw-toolbar-style = "raised-border";

          font-size = "11";
          font-feature = [ "-liga" "-calt" "-dlig" ];
          font-family = "\"Monaspace Neon\"";
        };
      };
    };
  };
}
