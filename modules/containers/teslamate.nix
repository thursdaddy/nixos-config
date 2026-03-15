_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "tesla";
      version = "3.0.0";

      cfg = config.mine.containers."${name}mate";
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";

      grafanaName = "tesla-grafana";
      grafanaCfg = config.mine.containers.${grafanaName};
      grafanaFqdn = "${grafanaCfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";

      dbName = "tesla-postgres";
      dbCfg = config.mine.containers.${dbName};
      dbFqdn = "${dbCfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers = {
        "${name}mate" = {
          enable = lib.mkEnableOption "${name}";
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = "teslamate";
          };
        };
        ${grafanaName} = {
          enable = lib.mkOption {
            description = "This is for blocky to create a DNS entry";
            type = lib.types.bool;
            default = cfg.enable;
          };
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = "tesla";
          };
        };
        ${dbName} = {
          enable = lib.mkOption {
            description = "This is for blocky to create a DNS entry";
            type = lib.types.bool;
            default = cfg.enable;
          };
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = "tesla-db";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "teslamate/teslamate:${version}";
            ports = [ "4000" ];
            environment = {
              DATABASE_HOST = "tesla-postgres";
              DATABASE_NAME = "teslamate";
              DATABASE_USER = "teslamate";
              MQTT_HOST = "tesla-mosquitto";
            };
            environmentFiles = [
              config.sops.templates."tesla.env".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/teslamate/:/opt/app/import"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "4000";
            };
          };

          "${grafanaName}" = {
            image = "teslamate/grafana:${version}";
            ports = [ "3000" ];
            environment = {
              PUID = "472";
              PGID = "472";
              TZ = "America/Phoenix";
              DATABASE_NAME = "teslamate";
              DATABASE_HOST = "tesla-postgres";
              DATABASE_USER = "teslamate";
            };
            environmentFiles = [
              config.sops.templates."grafana.env".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/tesla-grafana:/var/lib/grafana"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${grafanaName}.tls" = "true";
              "traefik.http.routers.${grafanaName}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${grafanaName}.entrypoints" = "websecure";
              "traefik.http.routers.${grafanaName}.rule" = "Host(`${grafanaFqdn}`)";
              "traefik.http.services.${grafanaName}.loadbalancer.server.port" = "3000";
              "enable.versions.check" = "false";
            };
          };

          "tesla-mosquitto" = {
            image = "eclipse-mosquitto:2";
            hostname = "tesla-mosquitto";
            ports = [ "1883" ];
            environment = {
              PUID = "1883";
              PGID = "1883";
            };
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/tesla-mosquitto/conf:/mosquitto/config"
              "${config.mine.containers.settings.configPath}/tesla-mosquitto/data:/mosquitto/data"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };

          "${dbName}" = {
            image = "postgres:17";
            ports = [ "5432" ];
            environment = {
              POSTGRES_USER = "teslamate";
              POSTGRES_DB = "teslamate";
            };
            environmentFiles = [
              config.sops.templates."postgres.env".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/tesla-postgres:/var/lib/postgresql/data"
              "${config.mine.containers.settings.configPath}/tesla-postgres/db_dumps:/db_dumps"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${dbName}.tls" = "true";
              "traefik.http.routers.${dbName}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${dbName}.entrypoints" = "websecure";
              "traefik.http.routers.${dbName}.rule" = "Host(`${dbFqdn}`)";
              "traefik.http.services.${dbName}.loadbalancer.server.port" = "5432";
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/tesla-postgres/db_dumps";
              "homelab.backup.retention.period" = "5";
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

        environment.etc =
          let
            alloyJournalTeslaMate = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "docker-${name}";
            };
            alloyJournalTeslaGrafana = lib.thurs.mkAlloyJournal {
              name = grafanaName;
              serviceName = "docker-${grafanaName}";
            };
            alloyJournalTeslaDb = lib.thurs.mkAlloyJournal {
              name = dbName;
              serviceName = "docker-${dbName}";
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
