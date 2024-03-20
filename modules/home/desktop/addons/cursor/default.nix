{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.home.cursor;
user = config.mine.user;

in {
  options.mine.home.cursor = {
    enable = mkOpt types.bool false "Enable Cursor theme";
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

