{ lib, config, inputs, pkgs, ... }:
with lib;
let

  cfg = config.mine.desktop.hyprland;

in {
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

    environment.systemPackages = with pkgs; [
      wdisplays
      wl-clipboard
      xdg-utils
    ];

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}
