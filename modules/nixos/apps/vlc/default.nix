{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.vlc;

in
{
  options.mine.apps.vlc = {
    enable = mkEnableOption "vlc";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.vlc
    ];
  };
}
