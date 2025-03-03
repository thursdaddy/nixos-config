{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.container.prometheus;

  version = "2.52.0";
  prometheus_config = pkgs.writeTextFile {
    name = "prometheus.yml";
    text = builtins.readFile config.mine.container.prometheus.configFile;
  };
in
{
  options.mine.container.prometheus = {
    enable = mkEnableOption "Enable prometheus container";
    version = mkOpt (types.nullOr types.str) "latest" "prometheus image version";
    configFile = mkOpt types.path ./prometheus.yml "prometheus config file path";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 9090 ];

    virtualisation.oci-containers.containers.prometheus = {
      user = "root:root";
      image = "prom/prometheus:v${version}";
      hostname = "prometheus";
      ports = [
        "0.0.0.0:9090:9090"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      cmd = [
        "--config.file=/etc/prometheus/prometheus.yml"
        "--storage.tsdb.retention.size=50GB"
      ];
      volumes = [
        "${prometheus_config}:/etc/prometheus/prometheus.yml"
        "${config.mine.container.settings.configPath}/prometheus:/prometheus"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.prometheus.tls" = "true";
        "traefik.http.routers.prometheus.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.prometheus.entrypoints" = "websecure";
        "traefik.http.routers.prometheus.rule" = "Host(`prometheus.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.prometheus.loadbalancer.server.port" = "9090";
        "enable.versions.check" = "false";
      };
    };
  };
}
