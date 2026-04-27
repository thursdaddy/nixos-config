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
      version = "1.26-nightly";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "gitea";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "gitea/gitea:${version}";
            ports = [
              "3000"
              "222:22"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/gitea/web:/data"
              "${config.mine.containers.settings.configPath}/gitea/backup:/backup"
            ];
            environment = {
              USER_UID = "1000";
              USER_GID = "1000";
              GITEA__database__DB_TYPE = "postgres";
              GITEA__database__HOST = "gitea-db:5432";
              GITEA__database__NAME = "gitea";
              GITEA__database__USER = "gitea";
              GITEA__migrations__ALLOWED_DOMAINS = "git.thurs.pw, github.com";
            };
            environmentFiles = [
              config.sops.templates."gitea-web".path
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
              "traefik.http.services.${name}.loadbalancer.server.port" = "3000";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}/backup";
              "homelab.backup.retention.period" = "5";
            };
          };
          "${name}-db" = {
            image = "docker.io/library/postgres:14";
            volumes = [
              "${config.mine.containers.settings.configPath}/gitea/postgres:/var/lib/postgresql/data"
            ];
            environment = {
              POSTGRES_DB = "gitea";
              POSTGRES_USER = "gitea";
            };
            environmentFiles = [
              config.sops.templates."gitea-db".path
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
              ];
              preStart = ''
                find ${config.mine.containers.settings.configPath}/gitea/backup -type f -iname "gitea-dump*" -delete
                docker exec -u git -w /backup gitea /app/gitea/gitea dump --skip-package-data -c /data/gitea/conf/app.ini
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
