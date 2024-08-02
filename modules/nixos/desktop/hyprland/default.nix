{ lib, config, inputs, pkgs, ... }:
with lib;
let

  cfg = config.mine.desktop.hyprland;

in
{
  options.mine.desktop.hyprland = {
    enable = mkEnableOption "Enable Hyprland Window Manager";
  };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    environment.systemPackages = with pkgs; [
      wdisplays
      wl-clipboard
      xdg-utils
      gnome3.adwaita-icon-theme
      hicolor-icon-theme
    ];

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
