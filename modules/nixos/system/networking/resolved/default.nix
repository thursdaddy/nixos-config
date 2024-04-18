{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.networking;

in
{
  options.mine.system.networking = {
    resolved = mkEnableOption "Enable systemd-resovled";
  };

  config = mkIf cfg.resolved {
    services.resolved = {
      enable = true;
      domains = [ "~." ];
    };
  };
}
