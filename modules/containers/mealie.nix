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
      version = "3.18.0";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;

      fqdn = "${name}.${config.mine.homelab.${config.networking.hostName}.rootDomainName}";
    in
    {
      options.mine.containers = {
        ${name} = {
          enable = lib.mkEnableOption "${name}";
        };
        "${name}-addon" = {
          enable = lib.mkOption {
            description = "Enable Blocky";
            type = lib.types.bool;
            default = true;
          };
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              port = 9000;
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "ghcr.io/mealie-recipes/${name}:v${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            volumes = [
              "${configPath}/${name}/app:/app/data"
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
            labels = {
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${configPath}/${name}";
              "homelab.backup.path.ignore" = "postgres";
            };
          };

          "${name}-db" = {
            image = "docker.io/library/postgres:17";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ name ];
            volumes = [
              "${configPath}/${name}/postgres:/var/lib/postgresql/data"
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
            labels = {
              "enable.versions.check" = "false";
            };
          };

          "${name}-addons" = {
            image = "ghcr.io/razziel89/mealie-addons:latest";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ name ];
            ports = [
              "9001:9000"
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

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs name;
              extraPackages = [
                pkgs.docker-client
              ];
              preStart = ''
                docker exec mealie-db /bin/sh -c "pg_dumpall -U mealie > /var/lib/postgresql/data/backup.sql"
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
