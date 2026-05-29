_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "pinepods";
      version = "0.8.2";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "pods";
        };
        tailscaleEntrypoint = lib.mkOption {
          description = "Set traefik entrypoint to tailscale Ip";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          traefik = {
            networks = [ "traefik-pinepods" ];
          };
          "${name}" = {
            image = "madeofpendletonwool/pinepods:${version}";
            pull = "always";
            networks = [
              "traefik-${name}"
              "${name}"
            ];
            ports = [
              "8040"
            ];
            environmentFiles = [
              config.sops.templates."pinepods-web".path
            ];
            environment = {
              DB_HOST = "${name}-db";
              DB_NAME = "pinepods";
              DB_PORT = "5432";
              DB_TYPE = "postgresql";
              DB_USER = "postgres";
              DEBUG_MODE = "true";
              HOSTNAME = "https://${fqdn}";
              LOG_LEVEL = "INFO";
              PEOPLE_API_URL = "https://people.pinepods.online";
              PGID = "995";
              PUID = "1000";
              SEARCH_API_URL = "https://search.pinepods.online/api/search";
              TZ = config.time.timeZone;
              VALKEY_HOST = "${name}-valkey";
              VALKEY_PORT = "6379";
            };
            volumes = [
              "/podcasts/pinepods:/opt/pinepods/downloads"
              "${config.mine.containers.settings.configPath}/${name}/metadata:/opt/pinepods/backups"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.docker.network" = "traefik-${name}";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "tailscale";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "8040";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/madeofpendletonwool/PinePods";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
              "homelab.backup.retention.period" = "5";
            };
          };

          "${name}-valkey" = {
            image = "valkey/valkey:8-alpine";
            hostname = "${name}-valkey";
            pull = "always";
            networks = [
              "${name}"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };

          "${name}-db" = {
            image = "docker.io/library/postgres:17";
            hostname = "${name}-db";
            networks = [
              "${name}"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/postgres:/var/lib/postgresql/data"
            ];
            environment = {
              POSTGRES_DB = "pinepods";
              POSTGRES_USER = "";
              PG_DATA = "/var/lib/postgresql/data/pgdata/";
            };
            environmentFiles = [
              config.sops.templates."pinepods-db".path
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };
        };

        mine.base.nfs-mounts = {
          enable = true;
          mounts = {
            "/podcasts" = {
              device = "192.168.10.12:/fast/podcasts";
            };
          };
        };

        systemd.services = {
          "init-docker-network-${name}" = {
            description = "Create Docker networks for Traefik isolation";
            after = [ "docker.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = [
                "-${lib.getExe pkgs.docker} network create traefik-${name}"
                "-${lib.getExe pkgs.docker} network create ${name}"
              ];
            };
          };
          docker-traefik = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
          "docker-${name}" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
          "docker-${name}-db" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
          "docker-${name}-valkey" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
        };

        sops = {
          secrets = {
            "pinepods/DB_PASSWORD" = { };
          };
          templates = {
            "pinepods-db".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."pinepods/DB_PASSWORD"}
            '';
            "pinepods-web".content = ''
              DB_PASSWORD=${config.sops.placeholder."pinepods/DB_PASSWORD"}
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
