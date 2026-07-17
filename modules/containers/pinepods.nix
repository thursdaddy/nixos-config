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
      configPath = config.mine.containers.settings.configPath;

      subdomain = "pods";
      fqdn = "${subdomain}.${config.mine.homelab.${config.networking.hostName}.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              port = 8040;
              tailscale = true;
              subDomain = subdomain;
            };
          };
          nfs-mounts = {
            enable = true;
            mounts = {
              "/podcasts" = {
                device = "192.168.10.12:/fast/podcasts";
              };
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "madeofpendletonwool/pinepods:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            environmentFiles = [
              config.sops.templates."pinepods-web".path
            ];
            environment = {
              DB_HOST = "${name}-db";
              DB_NAME = "pinepods";
              DB_PORT = "5432";
              DB_TYPE = "postgresql";
              DB_USER = "postgres";
              DEBUG_MODE = "true";
              HOSTNAME = "https://${fqdn}";
              LOG_LEVEL = "INFO";
              PEOPLE_API_URL = "https://people.pinepods.online";
              PGID = "995";
              PUID = "1000";
              SEARCH_API_URL = "https://search.pinepods.online/api/search";
              TZ = config.time.timeZone;
              VALKEY_HOST = "${name}-valkey";
              VALKEY_PORT = "6379";
            };
            volumes = [
              "/podcasts/pinepods:/opt/pinepods/downloads"
              "${configPath}/${name}/metadata:/opt/pinepods/backups"
            ];
            labels = {
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/madeofpendletonwool/PinePods";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${configPath}/${name}";
              "homelab.backup.path.ignore" = "postgres/pgdata";
            };
          };

          "${name}-valkey" = {
            image = "valkey/valkey:8-alpine";
            hostname = "${name}-valkey";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [
              "${name}"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };

          "${name}-db" = {
            image = "docker.io/library/postgres:17";
            hostname = "${name}-db";
            networks = [
              "${name}"
            ];
            volumes = [
              "${configPath}/${name}/postgres:/var/lib/postgresql/data"
            ];
            environment = {
              POSTGRES_DB = "pinepods";
              POSTGRES_USER = "";
              PG_DATA = "/var/lib/postgresql/data/pgdata/";
            };
            environmentFiles = [
              config.sops.templates."pinepods-db".path
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };
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

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs name;
              extraPackages = [
                pkgs.docker-client
              ];
              preStart = ''
                docker exec pinepods-db /bin/sh -c "pg_dumpall -U postgres -h localhost > /var/lib/postgresql/data/backup.sql"
              '';
            };
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
            "${alloyJournalBackup.name}" = alloyJournalBackup.value;
          };
      };
    };
}
