_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "gitea";
      version = "1.26.1";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.gitea = {
            traefik.container.port = 3000;
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "gitea/gitea:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            ports = [
              "222:22"
            ];
            volumes = [
              "${configPath}/gitea/web:/data"
              "${configPath}/gitea/backup:/backup"
            ];
            environment = {
              USER_UID = "1000";
              USER_GID = "1000";
              GITEA__database__DB_TYPE = "postgres";
              GITEA__database__HOST = "gitea-db:5432";
              GITEA__database__NAME = "gitea";
              GITEA__database__USER = "gitea";
              GITEA__migrations__ALLOWED_DOMAINS = "git.thurs.pw, github.com, api.github.com";
            };
            environmentFiles = [
              config.sops.templates."gitea-web".path
            ];
            labels = {
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${configPath}/${name}/backup";
              "homelab.backup.retention.period" = "5";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/go-gitea/gitea";
            };
          };

          "${name}-db" = {
            image = "docker.io/library/postgres:14";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ "${name}" ];
            volumes = [
              "${configPath}/gitea/postgres:/var/lib/postgresql/data"
            ];
            environment = {
              POSTGRES_DB = "gitea";
              POSTGRES_USER = "gitea";
            };
            environmentFiles = [
              config.sops.templates."gitea-db".path
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };
        };

        sops = {
          secrets = {
            "gitea/DB_PASS" = { };
          };
          templates = {
            "gitea-db".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."gitea/DB_PASS"}
            '';
            "gitea-web".content = ''
              GITEA__database__PASSWD=${config.sops.placeholder."gitea/DB_PASS"}
            '';
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService ({
              inherit pkgs name;
              extraPackages = [
                pkgs.docker-client
                pkgs.podman
              ];
              preStart = ''
                rm -f ${configPath}/gitea/backup/gitea-backup.zip || true
                ${config.mine.containers.settings.backend} exec -u git -w /backup gitea /app/gitea/gitea dump --skip-package-data -c /data/gitea/conf/app.ini -f /backup/gitea-backup.zip
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
              serviceName = "podman-${name}";
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
