_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "greenbook";
      version = "0.1.0";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
      dbName = "greenbook-db";
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
        "${dbName}" = {
          enable = lib.mkOption {
            description = "This is for blocky to create a DNS entry";
            type = lib.types.bool;
            default = cfg.enable;
          };
          subdomain = lib.mkOption {
            description = "DB Container url";
            type = lib.types.str;
            default = dbName;
          };
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "gitea.thurs.pw/homelab/greenbook:v${version}";
            login = {
              username = "thurs";
              registry = "gitea.thurs.pw";
              passwordFile = config.sops.templates."registry_pass".path;
            };
            hostname = name;
            ports = [
              "8000"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/greenbook/app:/app/data"
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            environmentFiles = [
              config.sops.templates."greenbook-app".path
            ];
            environment = {
              PAPERLESS_API_BASE_URL = "http://paperless-ngx-webserver:8000/api";
              PAPERLESS_HTTPS_URL = "https://paperless.thurs.pw/api";
              DB_HOST = "${dbName}";
              DB_USERNAME = "receipts";
              DB_NAME = "receipts";
              DB_PORT = "5432";
            };
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "8000";
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}";
              "homelab.backup.retention.period" = "5";
            };
          };

          "${dbName}" = {
            image = "postgres:17.6-alpine";
            hostname = dbName;
            ports = [
              "5432"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/greenbook/db:/var/lib/postgresql/data"
              "${config.mine.containers.settings.configPath}/greenbook/db_dumps:/db_dumps"
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            environmentFiles = [
              config.sops.templates."greenbook-db".path
            ];
            environment = {
              POSTGRES_USER = "receipts";
              POSTGRES_DB = "receipts";
              PGDATA = "/var/lib/postgresql/data/pgdata";
            };
            labels = {
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/greenbook/db_dumps";
              "homelab.backup.retention.period" = "5";
              "traefik.enable" = "true";
              "traefik.tcp.routers.${dbName}.tls" = "true";
              "traefik.tcp.routers.${dbName}.tls.certresolver" = "letsencrypt";
              "traefik.tcp.routers.${dbName}.entrypoints" = "websecure";
              "traefik.tcp.routers.${dbName}.rule" =
                "HostSNI(`${dbName}.${config.mine.containers.traefik.rootDomainName}`)";
              "traefik.tcp.services.${dbName}.loadbalancer.server.port" = "5432";
            };
          };

        };

        sops = {
          secrets = {
            "gitea/ROBOT_TOKEN" = {
              owner = "thurs";
            };
            "paperless/API_TOKEN" = {
              owner = "thurs";
            };
            "greenbook/DB_PASS" = {
              owner = "thurs";
            };
          };

          templates = {
            "registry_pass".content = ''
              ${config.sops.placeholder."gitea/ROBOT_TOKEN"}
            '';
            "greenbook-app".content = ''
              PAPERLESS_AUTH_TOKEN=${config.sops.placeholder."paperless/API_TOKEN"}
              DB_PASS=${config.sops.placeholder."greenbook/DB_PASS"}
            '';
            "greenbook-db".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."greenbook/DB_PASS"}
            '';
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService ({
              inherit pkgs name;
              extraPackages = [
                pkgs.docker-client
              ];
              preStart = ''
                docker exec greenbook-db /bin/sh -c "pg_dumpall -U receipts -h localhost > /db_dumps/receipts.sql"
              '';
            });
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "docker-${name}";
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
