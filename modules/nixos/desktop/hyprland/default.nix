{ lib, config, inputs, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.hyprland;

in {
  options.mine.nixos.hyprland = {
    enable = mkEnableOption "Enable Home-Manager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wdisplays
    ];

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      xwayland.enable = true;
    };

  };

}
