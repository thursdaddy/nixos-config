_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "pinepods";
      version = "0.8.2";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "pods";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "madeofpendletonwool/pinepods:${version}";
            ports = [
              "8040"
            ];
            environmentFiles = [
              config.sops.templates."pinepods-web".path
            ];
            environment = {
              TZ = config.time.timeZone;
              SEARCH_API_URL = "https://search.pinepods.online/api/search";
              PEOPLE_API_URL = "https://people.pinepods.online";
              HOSTNAME = "https://${fqdn}";
              DB_TYPE = "postgresql";
              DB_HOST = "${name}-db";
              DB_PORT = "5432";
              DB_USER = "postgres";
              DB_NAME = "pinepods";
              VALKEY_HOST = "${name}-valkey";
              VALKEY_PORT = "6379";
              DEBUG_MODE = "true";
              LOG_LEVEL = "INFO";
              PUID = "1000";
              PGID = "1000";
            };
            volumes = [
              # "${config.mine.containers.settings.configPath}/${name}/downloads:/opt/pinepods/downloads"
              "/podcasts/pinepods:/opt/pinepods/downloads"
              "${config.mine.containers.settings.configPath}/${name}/metadata:/opt/pinepods/backups"
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
              "traefik.http.services.${name}.loadbalancer.server.port" = "8040";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/madeofpendletonwool/PinePods";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
              "homelab.backup.retention.period" = "5";
            };
          };

          "${name}-valkey" = {
            image = "valkey/valkey:8-alpine";
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
          };

          "${name}-db" = {
            image = "docker.io/library/postgres:17";
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/postgres:/var/lib/postgresql/data"
            ];
            environment = {
              POSTGRES_DB = "pinepods";
              POSTGRES_USER = "";
              PG_DATA = "/var/lib/postgresql/data/pgdata/";
            };
            environmentFiles = [
              config.sops.templates."pinepods-db".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };
        };

        fileSystems."/podcasts" = {
          device = "192.168.10.12:/fast/podcasts";
          fsType = "nfs";
          options = [
            "auto"
            "rw"
            "defaults"
            "_netdev"
          ];
        };

        sops = {
          secrets = {
            "pinepods/DB_PASSWORD" = { };
          };
          templates = {
            "pinepods-db".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."pinepods/DB_PASSWORD"}
            '';
            "pinepods-web".content = ''
              DB_PASSWORD=${config.sops.placeholder."pinepods/DB_PASSWORD"}
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
