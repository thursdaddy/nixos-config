{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.nixos.firewall;

  in {
    options.mine.nixos.firewall = {
      enable = mkOpt types.bool true "Enable firewall";
    };

    config = mkIf cfg.enable {
      networking.firewall.enable = true;
    };

}
