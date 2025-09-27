{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.greenbook;

  version = "0.0.4";
in
{
  options.mine.container.greenbook = {
    enable = mkEnableOption "greenbook";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
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

    sops.templates."registry_pass".content = ''
      ${config.sops.placeholder."gitlab/REGISTRY_AUTH"}
    '';

    sops.templates."greenbook-app".content = ''
      PAPERLESS_AUTH_TOKEN=${config.sops.placeholder."paperless/API_TOKEN"}
      DB_PASS=${config.sops.placeholder."greenbook/DB_PASS"}
    '';

    sops.templates."greenbook-db".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."greenbook/DB_PASS"}
    '';

    networking.firewall.allowedTCPPorts = [ 5432 ];
    virtualisation.oci-containers.containers."greenbook-db" = {
      image = "postgres:17.6-alpine";
      hostname = "greenbook-db";
      ports = [
        "5432"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/greenbook/db:/var/lib/postgresql/data"
        "${config.mine.container.settings.configPath}/greenbook/db_dumps:/db_dumps"
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
        "traefik.enable" = "true";
        "traefik.tcp.routers.greenbook-db.rule" =
          "HostSNI(`greenbook-db.${config.mine.container.traefik.domainName}`)";
        "traefik.tcp.routers.greenbook-db.tls" = "true";
        "traefik.tcp.routers.greenbook-db.tls.certresolver" = "letsencrypt";
        "traefik.tcp.routers.greenbook-db.entrypoints" = "postgres";
        "traefik.tcp.routers.greenbook-db.service" = "greenbook-db-service";
        "traefik.tcp.services.greenbook-db-service.loadbalancer.server.port" = "5432";
        "enable.versions.check" = "false";
        "homelab.backup.enable" = "true";
        "homelab.backup.path" = "${config.mine.container.settings.configPath}/greenbook/db_dumps";
        "homelab.backup.retention.period" = "5";
      };
    };

    virtualisation.oci-containers.containers."greenbook" = {
      image = "reg.thurs.pw/homelab/greenbook:v${version}";
      login = {
        username = "thurs";
        registry = "reg.thurs.pw";
        passwordFile = config.sops.templates."registry_pass".path;
      };
      hostname = "greenbook";
      ports = [
        "8000"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/greenbook/app:/app/data"
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
        PAPERLESS_HTTPS_URL = "https://paperless.thusr.pw/api";
        DB_HOST = "greenbook-db";
        DB_USERNAME = "receipts";
        DB_NAME = "receipts";
        DB_PORT = "5432";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.greenbook.tls" = "true";
        "traefik.http.routers.greenbook.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.greenbook.entrypoints" = "websecure";
        "traefik.http.routers.greenbook.rule" =
          "Host(`greenbook.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.greenbook.loadbalancer.server.port" = "8000";
        "enable.versions.check" = "false";
        "homelab.backup.enable" = "true";
        "homelab.backup.path" = "${config.mine.container.settings.configPath}";
        "homelab.backup.retention.period" = "5";
      };
    };
  };
}
