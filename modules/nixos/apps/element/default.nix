{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.element;

in
{
  options.mine.apps.element = {
    enable = mkEnableOption "Element desktop client for Matrix";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      element-desktop-wayland
    ];
  };
}
