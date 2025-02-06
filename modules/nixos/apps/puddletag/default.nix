{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.puddletag;

in
{
  options.mine.apps.puddletag = {
    enable = mkEnableOption "puddletag";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      puddletag
    ];
  };
}
