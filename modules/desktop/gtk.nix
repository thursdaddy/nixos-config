{ inputs, ... }:
{
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
        };
        systemPackages = with pkgs; [
          tokyonight-gtk-theme
          papirus-icon-theme
          glib
        ];
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = [ "gtk" ];
      };

      programs.dconf.enable = true;
      services.dbus.packages = [ pkgs.gsettings-desktop-schemas ];
    };
}
