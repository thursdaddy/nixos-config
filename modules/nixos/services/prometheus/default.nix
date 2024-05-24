{ lib, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.services.prometheus;

in
{
  options.mine.services.prometheus = {
    enable = mkEnableOption "Enable Prometheus Exporter";
    exporters = mkOption {
      default = { };
      type = types.submodule {
        options = {
          node = mkOption {
            default = { };
            type = types.submodule {
              options = {
                enable = mkEnableOption "Enable node exporter";
                collectors = mkOpt (types.listOf types.str) [ "systemd" ] "List of node exporters";
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      exporters = {
        node = mkIf cfg.exporters.node.enable {
          enable = true;
          enabledCollectors = cfg.exporters.node.collectors;
          port = 9002;
          openFirewall = true;
        };
      };
    };
  };
}
