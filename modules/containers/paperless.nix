_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "paperless";
      version = "2.20.8";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";

      redisVersion = "8";
      postgresVersion = "17";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = name;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "paperless-ngx-broker" = {
            image = "docker.io/library/redis:${redisVersion}";
            volumes = [
              "${config.mine.containers.settings.configPath}/paperless/redis:/data"
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
              "${config.mine.containers.settings.configPath}/paperless/pgdata:/var/lib/postgresql/data"
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

          "${name}" = {
            image = "ghcr.io/paperless-ngx/paperless-ngx:${version}";
            ports = [
              "8000"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/paperless/data:/usr/src/paperless/data"
              "${config.mine.containers.settings.configPath}/paperless/media:/usr/src/paperless/media"
              "${config.mine.containers.settings.configPath}/paperless/user/export:/usr/src/paperless/export"
              "${config.mine.containers.settings.configPath}/paperless/user/consume:/usr/src/paperless/consume"
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            environment = {
              PAPERLESS_URL = "https://${fqdn}";
            };
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "8000";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/paperless-ngx/paperless-ngx";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/paperless/user/export";
              "homelab.backup.retention.period" = "5";
            };
            environment = {
              PAPERLESS_REDIS = "redis://paperless-ngx-broker:6379";
              PAPERLESS_DBHOST = "paperless-ngx-db";
            };
          };
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "docker-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
