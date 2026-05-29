_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "tracearr";
      version = "1.4.28";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "${name}";
        };
        tailscaleEntrypoint = lib.mkOption {
          description = "Set traefik entrypoint to tailscale Ip";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.docker = {
          extraOptions = "--default-ulimit nofile=65536:65536";
        };

        virtualisation.oci-containers.containers = {
          traefik = {
            networks = [ "traefik-${name}" ];
          };
          "${name}" = {
            image = "ghcr.io/connorgallopo/${name}:${version}";
            hostname = name;
            ports = [ "3000" ];
            networks = [
              "${name}"
              "traefik-${name}"
              "jellyfin"
              "plex"
            ];
            pull = "always";
            dependsOn = [
              "${name}-db"
              "${name}-redis"
            ];
            environment = {
              CORS_ORIGIN = "*";
              HOST = "0.0.0.0";
              LOG_LEVEL = "info";
              PORT = "3000";
              REDIS_URL = "redis://${name}-redis:6379";
              TZ = config.time.timeZone;
            };
            environmentFiles = [
              config.sops.templates."tracearr.env".path
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/app:/app/backend/backup-data"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.docker.network" = "traefik-${name}";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "tailscale";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.routers.${name}.observability.accesslogs" = "false";
              "traefik.http.services.${name}.loadbalancer.server.port" = "3000";
            };
          };

          "${name}-db" = {
            image = "timescale/timescaledb-ha:pg18.1-ts2.25.0";
            pull = "always";
            hostname = "${name}-db";
            networks = [ "${name}" ];
            ports = [
              "5432"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/db:/home/postgres/pgdata/data"
            ];
            extraOptions = [
              "--shm-size=512mb"
            ];
            environment = {
              POSTGRES_USER = "tracearr";
              POSTGRES_DB = "tracearr";
            };
            environmentFiles = [
              config.sops.templates."tracearr-db.env".path
            ];
            cmd = [
              "postgres"
              "-c"
              "timescaledb.license=timescale"
              "-c"
              "timescaledb.max_tuples_decompressed_per_dml_transaction=0"
              "-c"
              "max_locks_per_transaction=4096"
              "-c"
              "timescaledb.telemetry_level=off"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };

          "${name}-redis" = {
            image = "docker.io/library/redis:8-alpine";
            pull = "always";
            networks = [ "${name}" ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/redis:/data"
            ];
            cmd = [
              "redis-server"
              "--appendonly"
              "yes"
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };
        };

        sops = {
          secrets = {
            "tracearr/POSTGRES_PASSWORD" = { };
            "tracearr/JWT_SECRET" = { };
            "tracearr/COOKIE_SECRET" = { };
          };
          templates = {
            "tracearr-db.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."tracearr/POSTGRES_PASSWORD"}
            '';
            "tracearr.env".content = ''
              DATABASE_URL=postgres://tracearr:${
                config.sops.placeholder."tracearr/POSTGRES_PASSWORD"
              }@tracearr-db:5432/tracearr
              JWT_SECRET=${config.sops.placeholder."tracearr/JWT_SECRET"}
              COOKIE_SECRET=${config.sops.placeholder."tracearr/COOKIE_SECRET"}
            '';
          };
        };

        systemd.services = {
          init-docker-network-tracearr = {
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
          "docker-traefik" = {
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
          "docker-${name}-redis" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
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
