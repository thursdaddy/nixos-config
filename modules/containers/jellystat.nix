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
      version = "1.1.11";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            port = 3000;
            tailscale = true;
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "cyfershepard/${name}:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            dependsOn = [ "${name}-db" ];
            networks = [
              "jellyfin"
            ];
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
              "${configPath}/${name}/app:/app/backend/backup-data"
            ];
            labels = {
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/CyferShepard/Jellystat";
            };
          };

          "${name}-db" = {
            image = "postgres:15.2";
            hostname = "${name}-db";
            networks = [
              name
            ];
            ports = [
              "5432"
            ];
            volumes = [
              "${configPath}/${name}/db:/var/lib/postgresql/data"
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
