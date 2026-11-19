_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "bookorbit";
      version = "3.8.0";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
      backend = config.mine.containers.settings.backend;

      subdomain = "books";
      fqdn = "${subdomain}.${config.mine.homelab.${config.networking.hostName}.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            port = 3000;
            subDomain = subdomain;
          };
          nfs-mounts = {
            enable = true;
            mounts = {
              "/media/books" = {
                device = "192.168.10.12:/fast/books";
              };
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "ghcr.io/bookorbit/bookorbit:${version}";
            pull = if backend == "podman" then "newer" else "missing";
            dependsOn = [ "${name}-db" ];
            environment = {
              NODE_ENV = "production";
              PORT = "3000";
              POSTGRES_HOST = "${name}-db";
              POSTGRES_PORT = "5432";
              POSTGRES_USER = name;
              POSTGRES_DB = name;
              APP_URL = "https://${fqdn}";
              CLIENT_URL = "https://${fqdn}";
              TZ = config.time.timeZone;
              PUID = "1000";
              PGID = "1000";
              NODE_MAX_OLD_SPACE_SIZE = "2048";
            };
            environmentFiles = [
              config.sops.templates."${name}.env".path
            ];
            volumes = [
              "${configPath}/${name}/app:/data"
              "/media/books:/books"
            ];
            labels = {
              "org.opencontainers.image.version" = version;
              "org.opencontainers.image.source" = "https://github.com/bookorbit/bookorbit";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${configPath}/${name}";
              "homelab.backup.path.ignore" = "postgres";
            };
          };

          "${name}-db" = {
            image = "docker.io/pgvector/pgvector:pg18";
            pull = if backend == "podman" then "newer" else "missing";
            networks = [ name ];
            environment = {
              POSTGRES_USER = name;
              POSTGRES_DB = name;
              PGDATA = "/var/lib/postgresql/data/pgdata";
            };
            environmentFiles = [
              config.sops.templates."${name}-db.env".path
            ];
            volumes = [
              "${configPath}/${name}/postgres:/var/lib/postgresql/data"
              "${configPath}/${name}/db_backup:/backup"
            ];
            labels = {
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "false";
            };
          };
        };

        sops = {
          secrets = {
            "bookorbit/POSTGRES_PASSWORD" = { };
            "bookorbit/JWT_SECRET" = { };
            "bookorbit/SETUP_BOOTSTRAP_TOKEN" = { };
          };
          templates = {
            "${name}.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."bookorbit/POSTGRES_PASSWORD"}
              JWT_SECRET=${config.sops.placeholder."bookorbit/JWT_SECRET"}
              SETUP_BOOTSTRAP_TOKEN=${config.sops.placeholder."bookorbit/SETUP_BOOTSTRAP_TOKEN"}
            '';
            "${name}-db.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."bookorbit/POSTGRES_PASSWORD"}
            '';
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs name;
              extraPackages = [
                pkgs.docker-client
                pkgs.podman
              ];
              preStart = ''
                ${backend} exec ${name}-db /bin/sh -c "pg_dumpall -U ${name} > /backup/backup.sql"
              '';
            };
          in
          {
            services = {
              "backup-${name}" = backup.service;
              "${backend}-${name}" = {
                unitConfig.RequiresMountsFor = [ "/media/books" ];
              };
              "${backend}-${name}-db" = {
                after = [
                  "init-${backend}-network-${name}.service"
                  "systemd-tmpfiles-resetup.service"
                ];
                requires = [ "init-${backend}-network-${name}.service" ];
              };
            };
            timers."backup-${name}" = backup.timer;
            tmpfiles.rules = [
              "d ${configPath}/${name} 0755 ${config.mine.base.user.name} users -"
            ];
          };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${backend}-${name}";
            };
            alloyJournalDb = lib.thurs.mkAlloyJournal {
              name = "${name}-db";
              serviceName = "${backend}-${name}-db";
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          builtins.listToAttrs [
            alloyJournal
            alloyJournalDb
            alloyJournalBackup
          ];
      };
    };
}
