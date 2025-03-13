{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.freecad;

in
{
  options.mine.apps.freecad = {
    enable = mkEnableOption "Freecad";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      freecad
    ];
  };
}
