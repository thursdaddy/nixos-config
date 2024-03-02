{ lib, config, pkgs, ... }:
with lib;
let

cfg = config.mine.nixos.gthumb;

in {
  options.mine.nixos.gthumb = {
    enable = mkEnableOption "Gthumb";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      gthumb
    ];
  };

}
