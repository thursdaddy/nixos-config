{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.mine.services.prometheus;

in
{
  options.mine.services.prometheus = {
    enable = mkEnableOption "Enable Prometheus Exporter";
    exporters = mkOption {
      default = { };
      type = types.submodule {
        options = {
          smartctl.enable = mkEnableOption "Enable smartctl exporter";
          node.enable = mkEnableOption "Enable node exporter";
          zfs.enable = mkEnableOption "Enable node exporter";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      exporters = {
        node = mkIf cfg.exporters.node.enable {
          enable = true;
          enabledCollectors = [ "systemd" ];
          openFirewall = true;
        };
        smartctl = mkIf cfg.exporters.smartctl.enable {
          enable = true;
          openFirewall = true;
        };
        zfs = mkIf cfg.exporters.zfs.enable {
          enable = true;
          openFirewall = true;
        };
      };
    };
  };
}
