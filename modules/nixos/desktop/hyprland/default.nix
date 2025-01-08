{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.desktop.hyprland;

in
{
  options.mine.desktop.hyprland = {
    enable = mkEnableOption "Enable Hyprland Window Manager";
  };

  config = mkIf cfg.enable {
    services.displayManager.sddm.wayland.enable = mkIf config.mine.desktop.sddm.enable true;

    programs.hyprland = {
      package = pkgs.unstable.hyprland;
      enable = true;
      xwayland.enable = true;
    };

    environment.systemPackages = with pkgs; [
      wdisplays
      wl-clipboard
      xdg-utils
      adwaita-icon-theme
      hicolor-icon-theme
    ];

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
