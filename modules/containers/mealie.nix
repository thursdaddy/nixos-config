{ inputs, ... }:
{
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "mealie";
      version = "3.16.0";
      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers = {
        ${name} = {
          enable = lib.mkEnableOption "${name}";
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = name;
          };
        };
        "${name}-addon" = {
          enable = lib.mkOption {
            description = "Enable Blocky";
            type = lib.types.bool;
            default = true;
          };
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = "mealie-export";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "ghcr.io/mealie-recipes/${name}:v${version}";
            ports = [
              "9000"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/app:/app/data"
            ];
            environment = {
              "ALLOW_SIGNUP" = "false";
              "PUID" = "1000";
              "PGID" = "1000";
              "TZ" = config.time.timeZone;
              "BASE_URL" = "https://${fqdn}";
              "DB_ENGINE" = "postgres";
              "POSTGRES_USER" = "mealie";
              "POSTGRES_SERVER" = "${name}-db";
              "POSTGRES_PORT" = "5432";
              "POSTGRES_DB" = "mealie";
            };
            environmentFiles = [
              config.sops.templates."mealie-db.env".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "9000";
            };
          };

          "${name}-db" = {
            image = "docker.io/library/postgres:17";
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/postgres:/var/lib/postgresql/data"
            ];
            ports = [
              "5432"
            ];
            environment = {
              POSTGRES_DB = "mealie";
              POSTGRES_USER = "mealie";
            };
            environmentFiles = [
              config.sops.templates."mealie-db.env".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };

          "${name}-addons" = {
            image = "ghcr.io/razziel89/mealie-addons:latest";
            ports = [
              "9001:9000"
            ];
            volumes = [
              "mealie-data"
            ];
            environment = {
              MA_LISTEN_INTERFACE = ":9000";
              MA_RETRIEVAL_LIMIT = "5";
              MA_TIMEOUT_SECS = "60";
              MA_STARTUP_GRACE_SECS = "30";
              MEALIE_BASE_URL = "http://${name}";
              MEALIE_RETRIEVAL_URL = "http://${name}:9000";
              MEALIE_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsb25nX3Rva2VuIjp0cnVlLCJpZCI6ImQyNmRmODNmLTcxZGMtNDViNy1hZDg3LWE4MzZlZDY1NDQwMiIsIm5hbWUiOiJtZWFsaWUtYWRkb24iLCJpbnRlZ3JhdGlvbl9pZCI6ImdlbmVyaWMiLCJleHAiOjE5MzQwNDgxMzF9.LbW48S2VJklxKm64fbIhoikWj6uQhiVY4rY4ocssIGs";
              GIN_MODE = "release";
            };
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
          };
        };

        sops = {
          secrets = {
            "mealie/DB_PASS" = { };
          };
          templates = {
            "mealie-db.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."mealie/DB_PASS"}
            '';
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
