{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.gimp;

in
{
  options.mine.apps.gimp = {
    enable = mkEnableOption "Install GIMP";
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gimp
    ];
  };
}
