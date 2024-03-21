{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.desktop.cursor;
  user = config.mine.user;

in {
  options.mine.desktop.cursor = {
    enable = mkEnableOption "Enable Cursor theme";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.bibata-cursors-translucent;
        name = "Bibata_Ghost";
        size = 30;
      };
    };
  };
}
