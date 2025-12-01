{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.paperless-ngx;

  paperlessVersion = "2.20.0";
  redisVersion = "8";
  postgresVersion = "17";

in
{
  options.mine.container.paperless-ngx = {
    enable = mkEnableOption "Paperless-ngx document management system";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      "paperless-ngx-broker" = {
        image = "docker.io/library/redis:${redisVersion}";
        volumes = [
          "${config.mine.container.settings.configPath}/paperless/redis:/data"
        ];
        extraOptions = [
          "--network=traefik"
          "--pull=always"
        ];
        labels = {
          "enable.versions.check" = "false";
        };
      };

      "paperless-ngx-db" = {
        image = "docker.io/library/postgres:${postgresVersion}";
        volumes = [
          "${config.mine.container.settings.configPath}/paperless/pgdata:/var/lib/postgresql/data"
        ];
        environment = {
          POSTGRES_DB = "paperless";
          POSTGRES_USER = "paperless";
          POSTGRES_PASSWORD = "paperless";
        };
        extraOptions = [
          "--network=traefik"
          "--pull=always"
        ];
        labels = {
          "enable.versions.check" = "false";
        };
      };

      "paperless-ngx-webserver" = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:${paperlessVersion}";
        ports = [
          "8000"
        ];
        volumes = [
          "${config.mine.container.settings.configPath}/paperless/data:/usr/src/paperless/data"
          "${config.mine.container.settings.configPath}/paperless/media:/usr/src/paperless/media"
          "${config.mine.container.settings.configPath}/paperless/user/export:/usr/src/paperless/export"
          "${config.mine.container.settings.configPath}/paperless/user/consume:/usr/src/paperless/consume"
        ];
        extraOptions = [
          "--network=traefik"
          "--pull=always"
        ];
        environment = {
          PAPERLESS_URL = "https://paperless.thurs.pw";
        };
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.paperless.tls" = "true";
          "traefik.http.routers.paperless.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.paperless.entrypoints" = "websecure";
          "traefik.http.routers.paperless.rule" =
            "Host(`paperless.${config.mine.container.traefik.domainName}`)";
          "traefik.http.services.paperless.loadbalancer.server.port" = "8000";
          "org.opencontainers.image.version" = "${paperlessVersion}";
          "org.opencontainers.image.source" = "https://github.com/paperless-ngx/paperless-ngx";
          "homelab.backup.enable" = "true";
          "homelab.backup.path" = "${config.mine.container.settings.configPath}/paperless/user/export";
          "homelab.backup.retention.period" = "5";
        };
        environment = {
          PAPERLESS_REDIS = "redis://paperless-ngx-broker:6379";
          PAPERLESS_DBHOST = "paperless-ngx-db";
        };
      };
    };
  };
}
