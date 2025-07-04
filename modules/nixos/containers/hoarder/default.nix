{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.hoarder;

  version = "0.25.0";
  envFileContents = ''
    MEILI_MASTER_KEY=${config.sops.placeholder."hoarder/MEILI_MASTER_KEY"}
    NEXTAUTH_SECRET=${config.sops.placeholder."hoarder/MEILI_MASTER_KEY"}
  '';
in
{
  options.mine.container.hoarder = {
    enable = mkEnableOption "hoarder";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets."hoarder/MEILI_MASTER_KEY" = { };
      templates."hoarder.env".content = envFileContents;
    };

    virtualisation.oci-containers.containers = {
      "hoarder" = {
        image = "ghcr.io/karakeep-app/karakeep:${version}";
        ports = [
          "3000"
        ];
        volumes = [
          "${config.mine.container.settings.configPath}/hoarder:/data"
        ];
        extraOptions = [
          "--network=traefik"
          "--add-host=host.docker.internal:host-gateway"
          "--pull=always"
        ];
        environment = {
          NEXTAUTH_URL = "https://hoarder.${config.mine.container.traefik.domainName}";
          MEILI_ADDR = "http://meilisearch:7700";
          BROWSER_WEB_URL = "http://chrome:9222";
          DATA_DIR = "/data";
          OLLAMA_BASE_URL = "http://192.168.10.15:11434";
          INFERENCE_IMAGE_MODEL = "falcon3:latest";
          INFERENCE_TEXT_MODEL = "falcon3:latest";
          INFERENCE_JOB_TIMEOUT_SEC = "300";
        };
        environmentFiles = [
          config.sops.templates."hoarder.env".path
        ];
        labels = {
          "traefik.enable" = "true";
          "traefik.http.routers.hoarder.tls" = "true";
          "traefik.http.routers.hoarder.tls.certresolver" = "letsencrypt";
          "traefik.http.routers.hoarder.entrypoints" = "websecure";
          "traefik.http.routers.hoarder.rule" = "Host(`hoarder.${config.mine.container.traefik.domainName}`)";
          "traefik.http.services.hoarder.loadbalancer.server.port" = "3000";
          "org.opencontainers.image.version" = "${version}";
          "org.opencontainers.image.source" = "https://github.com/hoarder-app/hoarder";
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
          "${config.mine.container.settings.configPath}/hoarder_meilli:/meilli_data"
        ];
        labels = {
          "enable.versions.check" = "false";
        };
      };
    };
  };
}
