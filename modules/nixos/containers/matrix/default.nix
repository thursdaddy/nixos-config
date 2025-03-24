{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.matrix;

  version = "1.124.0";
in
{
  options.mine.container.matrix = {
    enable = mkEnableOption "matrix";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."matrix" = {
      image = "matrixdotorg/synapse:v${version}";
      ports = [
        "8008"
      ];
      environment = {
        TZ = "America/Phoenix";
        SYNAPSE_SERVER_NAME = "matrix.${config.mine.container.traefik.domainName}";
        UID = "1000";
        GID = "100";
      };
      volumes = [
        "${config.mine.container.settings.configPath}/matrix/data:/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.matrix.tls" = "true";
        "traefik.http.routers.matrix.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.matrix.entrypoints" = "websecure";
        "traefik.http.routers.matrix.rule" = "Host(`matrix.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.matrix.loadbalancer.server.port" = "8008";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/element-hq/synapse";
      };
    };
  };
}
