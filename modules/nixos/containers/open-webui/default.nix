{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.open-webui;

  version = "0.5.20";
in
{
  options.mine.container.open-webui = {
    enable = mkEnableOption "open-webui";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."open-webui" = {
      image = "ghcr.io/open-webui/open-webui:v${version}";
      ports = [
        "8080"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/open-webui:/app/backend/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--add-host=host.docker.internal:host-gateway"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.open-webui.tls" = "true";
        "traefik.http.routers.open-webui.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.open-webui.entrypoints" = "websecure";
        "traefik.http.routers.open-webui.rule" = "Host(`ollama.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.open-webui.loadbalancer.server.port" = "8080";
      };
    };
  };
}
