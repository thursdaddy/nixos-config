{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.loki;
  config_file = pkgs.writeTextFile {
    name = "loki-config.yaml";
    text = builtins.readFile ./loki-config.yaml;
  };
in
{
  options.mine.services.loki = {
    enable = mkEnableOption "Grafana Loki";
  };

  config = mkIf cfg.enable {
    environment.etc = mkIf config.mine.container.traefik.enable {
      "traefik/loki.yml" = {
        text = (
          builtins.readFile (
            pkgs.substituteAll {
              name = "loki";
              src = ./traefik.yml;
              fqdn = config.mine.container.traefik.domainName;
              ip = "192.168.10.120";
            }
          )
        );
      };
    };

    services.loki = {
      enable = true;
      configFile = config_file;
      dataDir = "/mnt/data/loki";
    };

    networking.firewall.allowedTCPPorts = [ 3100 ];

    mine.system.nfs-mounts = {
      mounts = {
        "/mnt/data/loki" = {
          device = "192.168.10.12:/fast/data/loki";
        };
      };
    };
  };
}
