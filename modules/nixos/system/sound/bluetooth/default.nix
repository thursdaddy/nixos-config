{ lib, config, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.bluetooth;

in {
  options.mine.nixos.bluetooth = {
    enable = mkOpt types.bool false "Enable bluetooth";
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

  };
}
