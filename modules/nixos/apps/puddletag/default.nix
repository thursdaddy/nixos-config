{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.puddletag;

in
{
  options.mine.apps.puddletag = {
    enable = mkEnableOption "puddletag";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      puddletag
    ];
  };
}
