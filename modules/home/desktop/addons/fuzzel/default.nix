{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.desktop.fuzzel;

in
{
  options.mine.desktop.fuzzel = {
    enable = mkEnableOption "Enable fuzzel";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = [
        pkgs.bemoji
      ];

      programs.fuzzel = {
        enable = true;
        settings = {
          main = {
            fuzzy = true;
            font = "Hack:size=11";
            dpi-aware = "yes";
            layer = "overlay";
            exit-on-keyboard-focus-loss = true;
            fields = "filename,name,generic";
            show-actions = false;
            horizontal-pad = 10;
            vertical-pad = 8;
            inner-pad = 0;
            image-size-ratio = 0.5;
            lines = 3;
            tabs = 2;
            width = 15;
          };
          colors = {
            background = "2E3440DD";
            text = "ECEFF4FF";
            match = "88C0D0FF";
            selection = "4C566AFF";
            selection-text = "ECEFF4FF";
            selection-match = "88C0D0FF";
            border = "2E3440FF";
          };
          border = {
            width = 2;
            radius = 4;
          };
          dmenu = {
            mode = "text";
            exit-immediately-if-empty = false;
          };
        };
      };
    };
  };
}
