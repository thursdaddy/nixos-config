{
  lib,
  config,
  pkgs,
  ...
}:
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
    home-manager.users.${user.name}.home = {
      pointerCursor = {
        gtk.enable = true;
        x11.enable = true;
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
      };
      file."adwaita-hyprcursor" =
        let
          themeSource =
            pkgs.fetchFromGitHub {
              owner = "joaoalves03";
              repo = "adwaita-hyprcursor";
              rev = "3fc6c5435b75c104cf6a156960900506af622ab4";
              sha256 = "sha256-4DQvZVXarkyNvLKCxP+j3VVG3+BjxcOno5NHRMamc5U=";
            }
            + "/hyprcursors";
        in
        {
          source = themeSource;
          target = ".local/share/icons/adwaita-hyprcursor";
        };

      packages = [ pkgs.hyprcursor ];

      sessionVariables = {
        WLR_NO_HARDWARE_CURSORS = 1;
        HYPRCURSOR_THEME = "adwaita-hyprcursor";
        HYPRCURSOR_SIZE = 24;
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = 24;
      };
    };
  };
}
