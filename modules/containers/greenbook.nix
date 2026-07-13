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
      port = 8000;
      dbPort = 5432;
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
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            inherit port;
          };
          apps."${name}-db".traefik.container = {
            port = dbPort;
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "gitea.thurs.pw/homelab/greenbook:v${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ "traefik" ];
            login = {
              username = "thurs";
              registry = "gitea.thurs.pw";
              passwordFile = config.sops.templates."registry_pass".path;
            };
            hostname = name;
            environmentFiles = [
              config.sops.templates."greenbook-app".path
            ];
            environment = {
              PAPERLESS_API_BASE_URL = "http://paperless-ngx-webserver:8000/api";
              PAPERLESS_HTTPS_URL = "https://paperless.thurs.pw/api";
              DB_HOST = "${name}-db";
              DB_USERNAME = "receipts";
              DB_NAME = "receipts";
              DB_PORT = "5432";
            };
            labels = {
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}";
            };
          };

          "${name}-db" = {
            image = "postgres:17.6-alpine";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ "traefik" ];
            volumes = [
              "${config.mine.containers.settings.configPath}/greenbook/db:/var/lib/postgresql/data"
              "${config.mine.containers.settings.configPath}/greenbook/db_dumps:/db_dumps"
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
            };
          };
        };

        sops = {
          secrets = {
            "gitea/ROBOT_TOKEN".owner = "thurs";
            "paperless/API_TOKEN".owner = "thurs";
            "greenbook/DB_PASS".owner = "thurs";
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
