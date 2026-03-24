_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "hoarder";
      version = "0.31.0";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = name;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "hoarder" = {
            image = "ghcr.io/karakeep-app/karakeep:${version}";
            ports = [
              "3000"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/hoarder:/data"
            ];
            extraOptions = [
              "--network=traefik"
              "--add-host=host.docker.internal:host-gateway"
              "--pull=always"
            ];
            environment = {
              NEXTAUTH_URL = "https://hoarder.${config.mine.containers.traefik.rootDomainName}";
              MEILI_ADDR = "http://meilisearch:7700";
              BROWSER_WEB_URL = "http://chrome:9222";
              DATA_DIR = "/data";
              OLLAMA_BASE_URL = "http://192.168.10.15:11434";
              INFERENCE_IMAGE_MODEL = "deepseek-r1:7b";
              INFERENCE_TEXT_MODEL = "deepseek-r1:7b";
              INFERENCE_JOB_TIMEOUT_SEC = "300";
              CRAWLER_FULL_PAGE_SCREENSHOT = "true";
              CRAWLER_VIDEO_DOWNLOAD = "true";
            };
            environmentFiles = [
              config.sops.templates."hoarder.env".path
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "3000";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/hoarder-app/hoarder";
              "homelab.backup.enable" = "false";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
              "homelab.backup.retention.period" = "5";
            };
          };

          "hoarder-chrome" = {
            image = "gcr.io/zenika-hub/alpine-chrome:123";
            hostname = "chrome";
            extraOptions = [
              "--network=traefik"
              "--pull=always"
            ];
            cmd = [
              "--no-sandbox"
              "--disable-gpu"
              "--disable-dev-shm-usage"
              "--remote-debugging-address=0.0.0.0"
              "--remote-debugging-port=9222"
              "--hide-scrollbars"
            ];
            labels = {
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "false";
            };
          };

          "hoarder-meilisearch" = {
            image = "getmeili/meilisearch:v1.11.1";
            hostname = "meilisearch";
            extraOptions = [
              "--network=traefik"
            ];
            environment = {
              MEILI_NO_ANALYTICS = "true";
            };
            volumes = [
              "${config.mine.containers.settings.configPath}/hoarder_meilli:/meilli_data"
            ];
            labels = {
              "enable.versions.check" = "false";
              "homelab.backup.enable" = "false";
            };
          };
        };

        sops = {
          secrets."hoarder/MEILI_MASTER_KEY" = { };
          templates."hoarder.env".content = ''
            MEILI_MASTER_KEY=${config.sops.placeholder."hoarder/MEILI_MASTER_KEY"}
            NEXTAUTH_SECRET=${config.sops.placeholder."hoarder/MEILI_MASTER_KEY"}
          '';
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
