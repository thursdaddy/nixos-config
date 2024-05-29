{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.system.networking.networkd;

in
{
  options.mine.system.networking.networkd = {
    enable = mkEnableOption "Enable Systemd-Networkd";
    hostname = mkOpt types.str "localhost" "Hostname";
  };

  config = mkIf cfg.enable {
    systemd.network.enable = true;

    networking = {
      useDHCP = true;
      useNetworkd = true;
      hostName = "${cfg.hostname}";
    };
  };
}
