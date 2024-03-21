{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.audio.pipewire;

in {
  options.mine.system.audio.pipewire = {
    enable = mkEnableOption "Enable pipewire audio";
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
