{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.teslamate;

  version = "1.32.0";
in
{
  options.mine.container.teslamate = {
    enable = mkEnableOption "teslamate";
  };

  config = mkIf cfg.enable {
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

    environment.etc."alloy/teslamate.alloy" = mkIf config.mine.services.alloy.enable {
      text = (
        builtins.readFile (
          pkgs.substituteAll {
            name = "teslamate.alloy";
            src = ./config.alloy;
            host = config.networking.hostName;
          }
        )
      );
    };

    virtualisation.oci-containers.containers = {
      "tesla" = {
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
          "${config.mine.container.settings.configPath}/teslamate/:/opt/app/import"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.tesla.tls" = "true";
          "traefik.http.routers.tesla.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.tesla.entrypoints" = "websecure";
          "traefik.http.routers.tesla.rule" = "Host(`teslamate.${config.mine.container.traefik.domainName}`)";
          "traefik.http.services.tesla.loadbalancer.server.port" = "4000";
        };
      };

      "tesla-grafana" = {
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
          "${config.mine.container.settings.configPath}/tesla-grafana:/var/lib/grafana"
        ];
        labels = {
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
        ];
        volumes = [
          "${config.mine.container.settings.configPath}/tesla-mosquitto/conf:/mosquitto/config"
          "${config.mine.container.settings.configPath}/tesla-mosquitto/data:/mosquitto/data"
        ];
        labels = {
          "enable.versions.check" = "false";
        };
      };

      "tesla-postgres" = {
        image = "postgres:13";
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
        ];
        volumes = [
          "${config.mine.container.settings.configPath}/tesla-postgres:/var/lib/postgresql/data"
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.tesla-postgres.tls" = "true";
          "traefik.http.routers.tesla-postgres.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.tesla-postgres.entrypoints" = "websecure";
          "traefik.http.routers.tesla-postgres.rule" =
            "Host(`tesla-db.${config.mine.container.traefik.domainName}`)";
          "traefik.http.services.tesla-postgres.loadbalancer.server.port" = "5432";
          "enable.versions.check" = "false";
        };
      };
    };
  };
}
