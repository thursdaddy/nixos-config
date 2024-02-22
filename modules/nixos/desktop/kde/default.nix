{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.mine.kde;

  in {
    options.mine.kde = {
      enable = mkEnableOption "KDE";
    };

    config = mkIf cfg.enable {
      services.xserver.enable = true;
      services.xserver.displayManager.sddm.enable = true;
      services.xserver.desktopManager.plasma5.enable = true;
    };

}
