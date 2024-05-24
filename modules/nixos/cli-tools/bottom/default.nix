{ pkgs, lib, config, ... }:
with lib;
let

  cfg = config.mine.cli-tools.bottom;

in
{
  options.mine.cli-tools.bottom = {
    enable = mkEnableOption "Enable bottom, a terminal based system monitor.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bottom
    ];
  };
}
