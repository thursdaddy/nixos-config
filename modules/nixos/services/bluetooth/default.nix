{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.services.bluetooth;

in {
  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };

    environment.systemPackages = [
      pkgs.blueman
    ];
  };
}
