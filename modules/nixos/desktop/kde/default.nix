{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.desktop.kde;

in
{
  options.mine.system.desktop.kde = {
    enable = mkEnableOption "KDE";
  };

  config = mkIf cfg.enable {
    services.xserver.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;
  };
}
