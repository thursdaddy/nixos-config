{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.tasktrove;

  version = "0.4.1";
in
{
  options.mine.container.tasktrove = {
    enable = mkEnableOption "tasktrove";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."tasktrove" = {
      image = "ghcr.io/dohsimpson/tasktrove:v${version}";
      ports = [
        "3000"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/tasktrove:/app/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.tasktrove.tls" = "true";
        "traefik.http.routers.tasktrove.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.tasktrove.entrypoints" = "websecure";
        "traefik.http.routers.tasktrove.rule" = "Host(`tasks.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.tasktrove.loadbalancer.server.port" = "3000";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/dohsimpson/TaskTrove";
      };
    };
  };
}
