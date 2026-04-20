_: {
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment = {
        sessionVariables = {
          GTK_THEME = "Tokyonight-Dark";
          GTK_USE_PORTAL = "1";

          # Force Qt to use Kvantum as its engine
          QT_QPA_PLATFORM = "wayland;xcb";
          QT_QPA_PLATFORMTHEME = "kvantum";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        };
        systemPackages = with pkgs; [
          tokyonight-gtk-theme
          papirus-icon-theme
          glib

          # Kvantum packages
          libsForQt5.qtstyleplugin-kvantum # For Qt5 apps
          kdePackages.qtstyleplugin-kvantum # For Qt6 apps like Picard
        ];
      };

      # Fix: Set platformTheme to null to avoid the "not of type" error
      # We manually set the variable in sessionVariables above instead.
      qt = {
        enable = true;
        platformTheme = null;
        style = "kvantum";
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-hyprland
        ];
        config.common.default = [ "gtk" ];
      };

      programs.dconf.enable = true;
      services.dbus.packages = [ pkgs.gsettings-desktop-schemas ];
    };
}
