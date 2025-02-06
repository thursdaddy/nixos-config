{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.protonvpn;

in
{
  options.mine.cli-tools.protonvpn = {
    enable = mkEnableOption "Enable ProtonVPN";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      unstable.protonvpn-cli
    ];
  };
}
