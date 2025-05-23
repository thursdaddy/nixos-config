{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.services.bluetooth;

in
{
  options.mine.system.services.bluetooth = {
    enable = mkEnableOption "Enable bluetooth";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        Policy = {
          AutoEnable = true;
        };
        General = {
          Experimental = true;
        };
      };
    };

    environment.systemPackages = [
      pkgs.blueman
    ];

    services.blueman.enable = true;
  };
}
