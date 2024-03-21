{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.sddm;

in {
  options.mine.desktop.sddm = {
    enable = mkOpt types.bool false "Enable SDDM";
    theme = mkOpt types.str "sugar-dark-sddm-theme" "SDDM theme";
  };

  config = mkIf cfg.enable {
    services.xserver.displayManager.sddm.enable = true;
#   services.xserver.displayManager.sddm.theme = "${ import ./themes/sugar-dark/theme.nix }";
  };
}
