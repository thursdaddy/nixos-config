{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.networking.forwarding;

in
{
  options.mine.system.networking.forwarding = {
    ipv4 = mkEnableOption "Enable ipv4 forwarding";
    ipv6 = mkEnableOption "Enable ipv6 forwarding";
  };

  config = mkIf (cfg.ipv4 || cfg.ipv6) {
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = mkIf cfg.ipv4 true;
      "net.ipv6.conf.all.forwarding" = mkIf cfg.ipv6 true;
    };
  };
}
