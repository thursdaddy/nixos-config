{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.networking.resolved;

in
{
  options.mine.system.networking.resolved = {
    enable = mkEnableOption "Enable systemd-resovled";
  };

  config = mkIf cfg.enable {
    services.resolved = {
      enable = true;
      domains = [ "~." ];
    };
  };
}
