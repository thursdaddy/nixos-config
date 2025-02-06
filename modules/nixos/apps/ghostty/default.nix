{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.ghostty;

in
{
  options.mine.apps.ghostty = {
    enable = mkEnableOption "Ghostty";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.unstable.ghostty
    ];
  };
}
