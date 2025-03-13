{
  lib,
  pkgs,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.desktop.sddm;

in
{
  options.mine.desktop.sddm = {
    enable = mkEnableOption "Enable SDDM";
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
