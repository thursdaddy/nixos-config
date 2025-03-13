{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.alertmanager;

  version = "0.28.0";
in
{
  options.mine.container.alertmanager = {
    enable = mkEnableOption "alertmanager";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."alertmanager" = {
      image = "prom/alertmanager:v${version}";
      ports = [
        "9093"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/alertmanager:/alertmanager/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.alertmanager.tls" = "true";
        "traefik.http.routers.alertmanager.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.alertmanager.entrypoints" = "websecure";
        "traefik.http.routers.alertmanager.rule" =
          "Host(`alertmanager.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.alertmanager.loadbalancer.server.port" = "9093";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/prometheus/alertmanager";
      };
    };
  };
}
