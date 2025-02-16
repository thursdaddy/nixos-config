{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.desktop.cursor;

in
{
  options.mine.desktop.cursor = {
    enable = mkEnableOption "Enable Cursor theme";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.bibata-cursors-translucent;
        name = "Bibata_Ghost";
        size = 24;
      };
    };
  };
}
