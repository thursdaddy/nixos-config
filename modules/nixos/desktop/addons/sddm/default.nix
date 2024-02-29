{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.sddm;

in {
  options.mine.nixos.sddm = {
    enable = mkOpt types.bool false "Enable SDDM";
    theme = mkOpt types.str "sugar-dark-sddm-theme" "SDDM theme";
  };

  config = mkIf cfg.enable {

    services.xserver = {
      enable = true;
      displayManager = {
        sddm.enable = true;
#        sddm.theme = "${ import ./themes/sugar-dark/theme.nix }";
      };
    };
  };
}
