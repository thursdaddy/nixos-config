_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "sparkyfitness";
      version = "0.16.6.3";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;

      subdomain = "fitness";
      fqdn = "${subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container = {
              port = 80;
              subDomain = subdomain;
            };
          };
        };
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "codewithcj/${name}:v${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            dependsOn = [ "${name}-server" ];
            environment = {
              SPARKY_FITNESS_FRONTEND_URL = "https://${fqdn}";
              SPARKY_FITNESS_SERVER_HOST = "${name}-server";
              SPARKY_FITNESS_SERVER_PORT = "3010";
              PUID = "1000";
              GUID = "1000";
            };
          };

          "${name}-db" = {
            image = "postgres:18.3-alpine";
            networks = [ name ];
            environmentFiles = [
              config.sops.templates."${name}-db.env".path
            ];
            environment = {
              PUID = "1000";
              GUID = "1000";
              POSTGRES_DB = "sparkyfitness";
              POSTGRES_USER = "sparky";
            };
            ports = [ "5432" ];
            extraOptions = [ "--network=traefik" ];
            volumes = [
              "${configPath}/${name}/db:/var/lib/postgresql"
            ];
          };

          "${name}-server" = {
            image = "codewithcj/${name}_server:v${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            dependsOn = [ "${name}-db" ];
            networks = [ name ];
            environmentFiles = [
              config.sops.templates."${name}-server.env".path
            ];
            environment = {
              PUID = "1000";
              GUID = "1000";
              SPARKY_FITNESS_DB_HOST = "${name}-db";
              SPARKY_FITNESS_DB_PORT = "5432";
              SPARKY_FITNESS_DB_NAME = "sparkyfitness";
              SPARKY_FITNESS_DB_USER = "sparky";
              SPARKY_FITNESS_APP_DB_USER = "sparkyapp";
              SPARKY_FITNESS_FRONTEND_URL = "https://${fqdn}";
            };
            volumes = [
              "${configPath}/${name}/app/backup:/app/SparkyFitnessServer/backup"
              "${configPath}/${name}/app/uploads:/app/SparkyFitnessServer/uploads"
            ];
          };
        };

        sops = {
          secrets = {
            "sparkyfitness/APP_DB_PASSWORD" = { };
            "sparkyfitness/API_ENCRYPTION_KEY" = { };
            "sparkyfitness/BETTER_AUTH_SECRET" = { };
            "sparkyfitness/POSTGRES_PASSWORD" = { };
          };
          templates = {
            "${name}-server.env".content = ''
              SPARKY_FITNESS_DB_PASSWORD=${config.sops.placeholder."sparkyfitness/POSTGRES_PASSWORD"}
              SPARKY_FITNESS_APP_DB_PASSWORD=${config.sops.placeholder."sparkyfitness/APP_DB_PASSWORD"}
              SPARKY_FITNESS_API_ENCRYPTION_KEY=${config.sops.placeholder."sparkyfitness/API_ENCRYPTION_KEY"}
              BETTER_AUTH_SECRET=${config.sops.placeholder."sparkyfitness/BETTER_AUTH_SECRET"}
            '';
            "${name}-db.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."sparkyfitness/POSTGRES_PASSWORD"}
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
