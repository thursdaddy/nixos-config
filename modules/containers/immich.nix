_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "immich";
      version = "3.0.2";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "pictures";
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              port = 2283;
              subDomain = cfg.subdomain;
              tailscale = true;
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "ghcr.io/immich-app/immich-server:v${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            dependsOn = [ "${name}-db" "${name}-redis" ];
            volumes = [
              "/mnt/pictures:/data"
            ];
            environment = {
              DB_HOSTNAME = "${name}-db";
              DB_USERNAME = "postgres";
              DB_PASSWORD = "postgrespassword";
              DB_DATABASE_NAME = "immich";
              REDIS_HOSTNAME = "${name}-redis";
              IMMICH_MACHINE_LEARNING_URL = "http://${name}-machine-learning:3003";
            };
            labels = {
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "/opt/configs/${name}/db_backup";
            };
          };

          "${name}-machine-learning" = {
            image = "ghcr.io/immich-app/immich-machine-learning:v${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ name ];
            volumes = [
              "/opt/configs/${name}/model-cache:/cache"
            ];
            environment = {
              IMMICH_HOST = "0.0.0.0";
            };
          };

          "${name}-db" = {
            image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ name ];
            volumes = [
              "/opt/configs/${name}/db:/var/lib/postgresql/data"
              "/opt/configs/${name}/db_backup:/backup"
            ];
            environment = {
              POSTGRES_DB = "immich";
              POSTGRES_USER = "postgres";
              POSTGRES_PASSWORD = "postgrespassword";
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };
          };

          "${name}-redis" = {
            image = "docker.io/valkey/valkey:9";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ name ];
            labels = {
              "enable.versions.check" = "false";
            };
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
                docker exec immich-db /bin/sh -c "pg_dumpall -U postgres > /backup/backup.sql"
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
