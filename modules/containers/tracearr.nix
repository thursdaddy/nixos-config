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
      configPath = config.mine.containers.settings.configPath;
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            port = 3000;
            tailscale = true;
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "ghcr.io/connorgallopo/${name}:${version}";
            hostname = name;
            user = "1000:100";
            networks = [
              "jellyfin"
              "plex"
              name
            ];
            dependsOn = [
              "${name}-db"
              "${name}-redis"
            ];
            environment = {
              CORS_ORIGIN = "*";
              HOST = "0.0.0.0";
              LOG_LEVEL = "warn";
              PORT = "3000";
              REDIS_URL = "redis://${name}-redis:6379";
              TZ = config.time.timeZone;
            };
            environmentFiles = [
              config.sops.templates."tracearr.env".path
            ];
            volumes = [
              "${configPath}/${name}/app:/app/backend/backup-data"
            ];
            labels = {
              "traefik.http.routers.${name}.observability.accesslogs" = "false";
            };
          };

          "${name}-db" = {
            image = "timescale/timescaledb-ha:pg18.1-ts2.25.0";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            hostname = "${name}-db";
            networks = [ name ];
            ports = [
              "5432"
            ];
            volumes = [
              "${configPath}/${name}/db:/home/postgres/pgdata/data"
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
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            user = "1000:100";
            networks = [ name ];
            volumes = [
              "${configPath}/${name}/redis:/data"
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

        systemd.tmpfiles.rules = [
          "Z ${configPath}/${name}/app 0755 thurs users -"
          "Z ${configPath}/${name}/redis 0755 thurs users -"
        ];

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

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
