_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      name = "gotify";
      version = "2.9.1";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = name;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "gotify/server:${version}";
          hostname = name;
          ports = [
            "80"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/gotify:/app/data/"
          ];
          extraOptions = [
            "--network=traefik"
            "--pull=always"
          ];
          environment = {
            TZ = config.time.timeZone;
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
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "80";
            "org.opencontainers.image.version" = "${version}";
            "org.opencontainers.image.source" = "https://github.com/gotify/server";
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
