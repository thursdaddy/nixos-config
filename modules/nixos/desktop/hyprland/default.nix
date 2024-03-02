{ lib, config, inputs, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.hyprland;

in {
  options.mine.nixos.hyprland = {
    enable = mkEnableOption "Enable Home-Manager";
  };

  imports = [
    inputs.hyprland.nixosModules.default
  ];

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.wdisplays
    ];

    programs.hyprland = {
      enable = true;
      xwayland.enable = false;
    };

  };

}
