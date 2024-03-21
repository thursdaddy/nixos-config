{ pkgs, lib, config, ... }:
with lib;
let

  cfg = config.mine.tools.bottom;

in {
  options.mine.tools.bottom = {
    enable = mkEnableOption "Enable bottom, a terminal based system monitor.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.bottom
    ];
  };
}
