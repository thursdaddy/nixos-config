_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "teslamate";
      version = "4.0.1";

      cfg = config.mine.containers.teslamate;
      configPath = config.mine.containers.settings.configPath;
    in
    {
      options.mine.containers = {
        "${name}" = {
          enable = lib.mkEnableOption "${name}";
        };
        teslamate-grafana = {
          enable = lib.mkOption {
            description = "This is for blocky to create a DNS entry";
            type = lib.types.bool;
            default = cfg.enable;
          };
        };
        teslamate-postgres = {
          enable = lib.mkOption {
            description = "This is for blocky to create a DNS entry";
            type = lib.types.bool;
            default = cfg.enable;
          };
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps = {
            ${name} = {
              traefik.container = {
                port = 4000;
                subDomain = "teslamate";
              };
            };
            teslamate-grafana = {
              traefik.container = {
                port = 3000;
                subDomain = "tesla";
              };
            };
            teslamate-postgres = {
              traefik.container = {
                port = 5432;
                subDomain = "tesla-db";
              };
            };
          };
        };

        virtualisation.oci-containers.containers = {
          ${name} = {
            image = "teslamate/teslamate:${version}";
            ports = [ "4000" ];
            environment = {
              DATABASE_HOST = "teslamate-postgres";
              DATABASE_NAME = "teslamate";
              DATABASE_USER = "teslamate";
              MQTT_HOST = "tesla-mosquitto";
            };
            environmentFiles = [
              config.sops.templates."tesla.env".path
            ];
            volumes = [
              "${configPath}/teslamate/:/opt/app/import"
            ];
          };

          teslamate-grafana = {
            image = "teslamate/grafana:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ name ];
            ports = [ "3000" ];
            environment = {
              PUID = "472";
              PGID = "472";
              TZ = "America/Phoenix";
              DATABASE_NAME = "teslamate";
              DATABASE_HOST = "teslamate-postgres";
              DATABASE_USER = "teslamate";
            };
            environmentFiles = [
              config.sops.templates."grafana.env".path
            ];
            volumes = [
              "${configPath}/tesla-grafana:/var/lib/grafana"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };

          teslamate-mosquitto = {
            image = "eclipse-mosquitto:2";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            networks = [ name ];
            hostname = "tesla-mosquitto";
            environment = {
              PUID = "1883";
              PGID = "1883";
            };
            volumes = [
              "${configPath}/tesla-mosquitto/conf:/mosquitto/config"
              "${configPath}/tesla-mosquitto/data:/mosquitto/data"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };

          "teslamate-postgres" = {
            image = "postgres:18-trixie";
            networks = [ name ];
            ports = [ "5432" ];
            environment = {
              POSTGRES_USER = "teslamate";
              POSTGRES_DB = "teslamate";
            };
            environmentFiles = [
              config.sops.templates."postgres.env".path
            ];
            volumes = [
              "${configPath}/tesla-postgres:/var/lib/postgresql"
              "${configPath}/tesla-postgres/db_dumps:/db_dumps"
            ];
            labels = {
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${configPath}/tesla-postgres/db_dumps";
            };
          };
        };

        sops = {
          secrets = {
            "teslamate/DATABASE_PASS" = { };
            "teslamate/ENCRYPTION_KEY" = { };
          };
          templates = {
            "tesla.env".content = ''
              DATABASE_PASS=${config.sops.placeholder."teslamate/DATABASE_PASS"}
              ENCRYPTION_KEY=${config.sops.placeholder."teslamate/ENCRYPTION_KEY"}
            '';
            "grafana.env".content = ''
              DATABASE_PASS=${config.sops.placeholder."teslamate/DATABASE_PASS"}
            '';
            "postgres.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."teslamate/DATABASE_PASS"}
            '';
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService ({
              inherit pkgs;
              name = "teslamate-postgres";
              extraPackages = [
                pkgs.docker-client
                pkgs.podman
              ];
              preStart = ''
                ${config.mine.containers.settings.backend} exec -t teslamate-postgres /bin/sh -c "pg_dump -U teslamate -h localhost > /db_dumps/teslamate.sql"
              '';
            });
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        environment.etc =
          let
            alloyJournalTeslaMate = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
            alloyJournalTeslaGrafana = lib.thurs.mkAlloyJournal {
              name = "teslamate-grafana";
              serviceName = "${config.mine.containers.settings.backend}-teslamate-grafana";
            };
            alloyJournalTeslaDb = lib.thurs.mkAlloyJournal {
              name = "teslamate-postgres";
              serviceName = "${config.mine.containers.settings.backend}-teslamate-postgres";
            };
          in
          builtins.listToAttrs [
            alloyJournalTeslaMate
            alloyJournalTeslaGrafana
            alloyJournalTeslaDb
          ];
      };
    };
}
