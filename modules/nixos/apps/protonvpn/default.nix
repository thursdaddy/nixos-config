{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.apps.protonvpn;

in
{
  options.mine.apps.protonvpn = {
    enable = mkEnableOption "Enable ProtonVPN";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      protonvpn-gui
    ];
  };
}
