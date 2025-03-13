{
  pkgs,
  lib,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
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
