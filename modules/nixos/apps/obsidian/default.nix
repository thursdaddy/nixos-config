{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.obsidian;

in {
  options.mine.nixos.obsidian = {
    enable = mkEnableOption "obsidian";
  };

  config = lib.mkIf cfg.enable  {
    nixpkgs.config.permittedInsecurePackages = [
      "electron-25.9.0"
    ];

    environment.systemPackages = [
      pkgs.obsidian
    ];

  };
}
