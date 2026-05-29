_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "jellystat";
      version = "1.1.10";

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
        tailscaleEntrypoint = lib.mkOption {
          description = "Set traefik entrypoint to tailscale Ip";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          traefik = {
            networks = [ "traefik-${name}" ];
          };
          "${name}" = {
            image = "cyfershepard/${name}:${version}";
            pull = "always";
            dependsOn = [ "${name}-db" ];
            networks = [
              "${name}"
              "traefik-${name}"
              "jellyfin"
            ];
            ports = [ "3000" ];
            environment = {
              TZ = config.time.timeZone;
              POSTGRES_USER = "postgres";
              POSTGRES_IP = "${name}-db";
              POSTGRES_PORT = "5432";
            };
            environmentFiles = [
              config.sops.templates."jellystat.env".path
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/app:/app/backend/backup-data"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.docker.network" = "traefik-${name}";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "tailscale";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "3000";
            };
          };

          "${name}-db" = {
            image = "postgres:15.2";
            hostname = "${name}-db";
            networks = [
              "${name}"
            ];
            ports = [
              "5432"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}/db:/var/lib/postgresql/data"
            ];
            extraOptions = [
              "--shm-size=1gb"
            ];
            environment = {
              POSTGRES_USER = "postgres";
            };
            environmentFiles = [
              config.sops.templates."jellystat-db.env".path
            ];
            labels = {
              "enable.versions.check" = "false";
            };
          };
        };

        sops = {
          secrets = {
            "jellystat/POSTGRES_PASSWORD" = { };
            "jellystat/JWT_SECRET" = { };
          };
          templates = {
            "jellystat-db.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."jellystat/POSTGRES_PASSWORD"}
            '';
            "jellystat.env".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."jellystat/POSTGRES_PASSWORD"}
              JWT_SECRET=${config.sops.placeholder."jellystat/POSTGRES_PASSWORD"}
            '';
          };
        };

        systemd.services = {
          "init-docker-network-${name}" = {
            description = "Create Docker networks for Traefik isolation";
            after = [ "docker.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = [
                "-${lib.getExe pkgs.docker} network create traefik-${name}"
                "-${lib.getExe pkgs.docker} network create ${name}"
              ];
            };
          };
          docker-traefik = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
          "docker-${name}" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
          "docker-${name}-db" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
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
