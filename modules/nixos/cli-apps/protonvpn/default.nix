{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.cli-apps.protonvpn;

in
{
  options.mine.cli-apps.protonvpn = {
    enable = mkEnableOption "Enable ProtonVPN";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      protonvpn-cli
    ];
  };
}
