{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.obsidian;

in
{
  options.mine.apps.obsidian = {
    enable = mkEnableOption "obsidian";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.permittedInsecurePackages = [
      "electron-25.9.0"
    ];

    environment.systemPackages = with pkgs; [
      obsidian
    ];
  };
}
