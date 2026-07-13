_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "gotify";
      version = "2.9.1";

      cfg = config.mine.containers.${name};
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine = {
          homelab.${config.networking.hostName} = {
            apps.gotify = {
              traefik = {
                domain = "thurs.cloud";
                container = {
                  tailscale = true;
                  dns = false;
                  port = 80;
                };
              };
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "gotify/server:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            hostname = name;
            volumes = [
              "${config.mine.containers.settings.configPath}/gotify:/app/data/"
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
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/gotify/server";
              "traefik.http.routers.${name}.middlewares" = "${name}-ratelimit,fail2ban";
              "traefik.http.middlewares.${name}-ratelimit.ratelimit.average" = "100";
              "traefik.http.middlewares.${name}-ratelimit.ratelimit.burst" = "250";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.bantime" = "3h";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.findtime" = "5m";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.maxretry" = "5";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.statuscode" = "401";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.enabled" = "true";
              "traefik.http.routers.${name}.entrypoints" = lib.mkForce "websecure,tailscale";
            };
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
