{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.mine.firewall;

  in {
    options.mine.firewall = {
      enable = mkEnableOption "Enable Firewall";
    };

    config = mkIf cfg.enable {
      networking.firewall.enable = true;
    };

}
