{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.rwmarkable;

  version = "1.6.1";
in
{
  options.mine.container.rwmarkable = {
    enable = mkEnableOption "rwmarkable";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."rwmarkable" = {
      image = "ghcr.io/fccview/rwmarkable:${version}";
      user = "1000";
      ports = [
        "3000"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/rwmarkable:/app/data"
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
        "traefik.http.routers.rwmarkable.tls" = "true";
        "traefik.http.routers.rwmarkable.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.rwmarkable.entrypoints" = "websecure";
        "traefik.http.routers.rwmarkable.rule" =
          "Host(`lists.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.rwmarkable.loadbalancer.server.port" = "3000";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/fccview/rwMarkable";
      };
    };
  };
}
