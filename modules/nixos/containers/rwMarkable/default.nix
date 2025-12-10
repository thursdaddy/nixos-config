{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.jotty;

  version = "1.12.2";
in
{
  options.mine.container.jotty = {
    enable = mkEnableOption "jotty";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."jotty" = {
      image = "ghcr.io/fccview/jotty:${version}";
      user = "1000";
      ports = [
        "3000"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/jotty:/app/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      environment = {
        NODE_ENV = "production";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.jotty.tls" = "true";
        "traefik.http.routers.jotty.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.jotty.entrypoints" = "websecure";
        "traefik.http.routers.jotty.rule" = "Host(`lists.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.jotty.loadbalancer.server.port" = "3000";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/fccview/rwMarkable";
      };
    };
  };
}
