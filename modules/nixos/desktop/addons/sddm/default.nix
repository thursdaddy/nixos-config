{ lib, pkgs, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.desktop.sddm;

in
{
  options.mine.desktop.sddm = {
    enable = mkOpt types.bool false "Enable SDDM";
    theme = mkOpt types.str "sugar-dark-sddm-theme" "SDDM theme";
  };

  config = mkIf cfg.enable {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.theme = "Elegant";

    environment.systemPackages = with pkgs; [
      elegant-sddm
    ];
  };
}
