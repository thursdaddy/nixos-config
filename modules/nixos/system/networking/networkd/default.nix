{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.thurs) mkOpt;
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
