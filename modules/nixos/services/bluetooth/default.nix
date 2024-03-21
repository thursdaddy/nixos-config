{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.services.bluetooth;

in {
  options.mine.services.bluetooth = {
    enable = mkEnableOption "Enable bluetooth";
  };

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
