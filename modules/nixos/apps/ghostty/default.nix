{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.ghostty;

in
{
  options.mine.apps.ghostty = {
    enable = mkEnableOption "Ghostty";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.unstable.ghostty
    ];
  };
}
