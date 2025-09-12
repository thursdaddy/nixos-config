{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.receipts-db;

  version = "13-alpine";
in
{
  options.mine.container.receipts-db = {
    enable = mkEnableOption "receipts-db";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 5432 ];
    virtualisation.oci-containers.containers."receipts-db" = {
      image = "postgres:${version}";
      hostname = "receipts-db";
      ports = [
        "5432:5432"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/receipts-db:/receipts-db/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      environment = {
        POSTGRES_USER = "receipts";
        POSTGRES_PASSWORD = "receipts";
        POSTGRES_DB = "receipts";
        PGDATA = "/receeipts-db/data";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.receipts-db.tls" = "true";
        "traefik.http.routers.receipts-db.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.receipts-db.entrypoints" = "websecure";
        "traefik.http.routers.receipts-db.rule" =
          "Host(`receipts-db.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.receipts-db.loadbalancer.server.port" = "5432";
        "enable.versions.check" = "false";
      };
    };
  };
}
