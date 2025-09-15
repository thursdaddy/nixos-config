{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.greenbook;
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
        "traefik.http.routers.greenbook.tls" = "true";
        "traefik.http.routers.greenbook.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.greenbook.entrypoints" = "websecure";
        "traefik.http.routers.greenbook.rule" =
          "Host(`greenbook-db.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.greenbook.loadbalancer.server.port" = "5432";
        "enable.versions.check" = "false";
      };
    };

    virtualisation.oci-containers.containers."greenbook" = {
      image = "reg.thurs.pw/homelab/greenbook";
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
        PAPERLESS_API_BASE_URL = "https://paperless.thurs.pw/api";
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
      };
    };
  };
}
