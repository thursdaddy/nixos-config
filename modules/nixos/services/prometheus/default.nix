{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.services.prometheus;

in
{
  options.mine.services.prometheus = {
    enable = mkEnableOption "Enable Prometheus Exporter";
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
          openFirewall = true;
        };
        smartctl = {
          enable = true;
          openFirewall = true;
        };
      };
    };
  };
}
