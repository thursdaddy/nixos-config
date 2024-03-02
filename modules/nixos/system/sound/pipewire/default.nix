{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.pipewire;

in {
  options.mine.nixos.pipewire = {
    enable = mkOpt types.bool false "Enable pipewire audio";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [
      pkgs.pavucontrol
    ];

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

  };
}
