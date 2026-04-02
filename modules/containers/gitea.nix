_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "gitea";
      version = "1.25.5";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "gitea";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "gitea/gitea:${version}";
            ports = [
              "3000"
              "222:22"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/gitea/web:/data"
            ];
            environment = {
              USER_UID = "1000";
              USER_GID = "1000";
              GITEA__database__DB_TYPE = "postgres";
              GITEA__database__HOST = "gitea-db:5432";
              GITEA__database__NAME = "gitea";
              GITEA__database__USER = "gitea";
              GITEA__migrations__ALLOWED_DOMAINS = "git.thurs.pw, github.com";
            };
            environmentFiles = [
              config.sops.templates."gitea-web".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "3000";
            };
          };
          "${name}-db" = {
            image = "docker.io/library/postgres:14";
            volumes = [
              "${config.mine.containers.settings.configPath}/gitea/postgres:/var/lib/postgresql/data"
            ];
            environment = {
              POSTGRES_DB = "gitea";
              POSTGRES_USER = "gitea";
            };
            environmentFiles = [
              config.sops.templates."gitea-db".path
            ];
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
          };
        };

        sops = {
          secrets = {
            "gitea/DB_PASS" = { };
          };
          templates = {
            "gitea-db".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."gitea/DB_PASS"}
            '';
            "gitea-web".content = ''
              GITEA__database__PASSWD=${config.sops.placeholder."gitea/DB_PASS"}
            '';
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
