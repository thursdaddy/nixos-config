{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.keybase;

in
{
  options.mine.apps.keybase = {
    enable = mkEnableOption "keybase";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      keybase
      keybase-gui
    ];

    services.keybase.enable = true;
  };
}
