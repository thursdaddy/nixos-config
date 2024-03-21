{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.gthumb;

in {
  options.mine.apps.gthumb = {
    enable = mkEnableOption "Gthumb";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gthumb
    ];
  };
}
