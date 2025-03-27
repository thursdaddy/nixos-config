{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.gotify;

  version = "2.6.1";
in
{
  options.mine.container.gotify = {
    enable = mkEnableOption "gotify";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."gotify" = {
      image = "gotify/server:${version}";
      hostname = "gotify";
      ports = [
        "80"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/gotify:/app/data/"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      environment = {
        TZ = config.mine.system.timezone.location;
        GOTIFY_DATABASE_DIALECT = "sqlite3";
        GOTIFY_DATABASE_CONNECTION = "data/gotify.db";
        GOTIFY_DEFAULTUSER_NAME = "admin";
        GOTIFY_DEFAULTUSER_PASS = "admin"; # only valid during first startup
        GOTIFY_PASSSTRENGTH = "15";
        GOTIFY_UPLOADEDIMAGESDIR = "data/images";
        GOTIFY_PLUGINSDIR = "data/plugins";
        GOTIFY_REGISTRATION = "false";
      };
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.gotify.tls" = "true";
        "traefik.http.routers.gotify.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.gotify.entrypoints" = "websecure";
        "traefik.http.routers.gotify.rule" = "Host(`gotify.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.gotify.loadbalancer.server.port" = "80";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/gotify/server";
      };
    };

    environment.etc = {
      "alloy/gotify.alloy" = mkIf config.mine.services.alloy.enable {
        text = builtins.readFile ./config.alloy;
      };
    };
  };
}
