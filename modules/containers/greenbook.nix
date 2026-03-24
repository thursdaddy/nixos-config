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
      version = "0.0.4";

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
        virtualisation.oci-containers.containers."${dbName}" = {
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
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "reg.thurs.pw/homelab/greenbook:v${version}";
          login = {
            username = "thurs";
            registry = "reg.thurs.pw";
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
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
            "homelab.backup.retention.period" = "5";
          };
        };

        sops = {
          secrets = {
            "gitlab/REGISTRY_AUTH" = {
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
              ${config.sops.placeholder."gitlab/REGISTRY_AUTH"}
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

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "docker-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
