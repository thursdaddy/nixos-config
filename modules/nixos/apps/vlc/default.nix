{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.vlc;

in {
  options.mine.nixos.vlc = {
    enable = mkEnableOption "vlc";
  };

  config = lib.mkIf cfg.enable  {

    environment.systemPackages = [
      pkgs.vlc
    ];

  };
}
