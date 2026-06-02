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
      version = "0.32.0";

      cfg = config.mine.containers.${name};
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
        mine.homelab.${config.networking.hostName} = {
          apps.hoarder = {
            traefik = {
              container = {
                port = 3000;
              };
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "hoarder" = {
            image = "ghcr.io/karakeep-app/karakeep:${version}";
            pull = "always";
            networks = [ "traefik" ];
            volumes = [
              "${config.mine.containers.settings.configPath}/hoarder:/data"
            ];
            extraOptions = [
              "--add-host=host.docker.internal:host-gateway"
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
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/hoarder-app/hoarder";
              "homelab.backup.enable" = "false";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
              "homelab.backup.retention.period" = "5";
            };
          };

          "hoarder-chrome" = {
            image = "gcr.io/zenika-hub/alpine-chrome:123";
            pull = "always";
            networks = [ "traefik" ];
            hostname = "chrome";
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
            pull = "always";
            networks = [ "traefik" ];
            hostname = "meilisearch";
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
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
