{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.networking.firewall;

in {
  options.mine.system.networking.firewall = {
    enable = mkEnableOption "Enable firewall";
  };

  config = mkIf cfg.enable {
    networking.firewall.enable = true;
  };
}
