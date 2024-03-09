{ lib, config, inputs, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.hyprland;

in {
  options.mine.nixos.hyprland = {
    enable = mkEnableOption "Enable Hyprland system package";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wdisplays
      wl-clipboard
    ];

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

  };

}
