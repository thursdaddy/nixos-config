{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.grocy;

  version = "4.4.1";
in
{
  options.mine.container.grocy = {
    enable = mkEnableOption "grocy";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."grocy" = {
      image = "linuxserver/grocy:${version}";
      ports = [
        "80"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Phoenix";
        BASE_URL = "https://grocery.${config.mine.container.traefik.domainName}";
      };
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/grocy:/config"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.grocy.tls" = "true";
        "traefik.http.routers.grocy.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.grocy.entrypoints" = "websecure";
        "traefik.http.routers.grocy.rule" = "Host(`grocery.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.grocy.loadbalancer.server.port" = "80";
      };
    };
    virtualisation.oci-containers.containers."barcodebuddy" = {
      image = "f0rc3/barcodebuddy:latest";
      ports = [
        "80"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
        TZ = "America/Phoenix";
        BBUDDY_EXTERNAL_GROCY_URL = "https://grocery.${config.mine.container.traefik.domainName}";
        IGNORE_SSL_CA = "true";
        IGNORE_SSL_HOST = "true";
      };
      extraOptions = [
        "--network=traefik"
        "--pull=always"
        "--dns=192.168.20.52"
        "--dns=192.168.20.51"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/barcodebuddy:/config"
      ];
      labels = {
        "traefik.enable" = "true";
        "enable.versions.check" = "false";
        "traefik.http.routers.barcodebuddy.tls" = "true";
        "traefik.http.routers.barcodebuddy.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.barcodebuddy.entrypoints" = "websecure";
        "traefik.http.routers.barcodebuddy.rule" = "Host(`barcode.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.barcodebuddy.loadbalancer.server.port" = "80";
      };
    };
  };
}
