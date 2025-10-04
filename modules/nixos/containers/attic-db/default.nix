{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.attic-db;
in
{
  options.mine.container.attic-db = {
    enable = mkEnableOption "attic";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        "attic/DB_PASS" = {
          owner = "thurs";
        };
      };
      templates = {
        "attic-db".content = ''
          POSTGRES_PASSWORD=${config.sops.placeholder."attic/DB_PASS"}
        '';
      };
    };

    virtualisation.oci-containers.containers."attic-db" = {
      image = "postgres:17.6-alpine";
      hostname = "attic-db";
      ports = [
        "0.0.0.0:54545:5432"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/attic/db:/var/lib/postgresql/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      environmentFiles = [
        config.sops.templates."attic-db".path
      ];
      environment = {
        POSTGRES_USER = "attic";
        POSTGRES_DB = "attic";
        PGDATA = "/var/lib/postgresql/data/pgdata";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.tcp.routers.attic-db.rule" =
          "HostSNI(`attic-db.${config.mine.container.traefik.domainName}`)";
        "traefik.tcp.routers.attic-db.tls" = "true";
        "traefik.tcp.routers.attic-db.tls.certresolver" = "letsencrypt";
        "traefik.tcp.routers.attic-db.entrypoints" = "postgres";
        "traefik.tcp.routers.attic-db.service" = "attic-db-service";
        "traefik.tcp.services.attic-db-service.loadbalancer.server.port" = "5432";
        "enable.versions.check" = "false";
      };
    };
  };
}
