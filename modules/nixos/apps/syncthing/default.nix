{ lib, config, ... }:
with lib;
let

  cfg = config.mine.apps.syncthing;

in {
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 8384 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];
  };
}
