{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.overseerr;

  version = "1.33.2";
in
{
  options.mine.container.overseerr = {
    enable = mkEnableOption "overseerr";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."overseerr" = {
      image = "linuxserver/overseerr:${version}";
      ports = [
        "5055"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
      };
      extraOptions = [
        "--network=traefik"
        "--pull=always"
        "--dns=192.168.10.57"
        "--dns=192.168.10.201"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/overseerr:/config"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.overseerr.tls" = "true";
        "traefik.http.routers.overseerr.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.overseerr.entrypoints" = "websecure";
        "traefik.http.routers.overseerr.rule" =
          "Host(`request.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.overseerr.loadbalancer.server.port" = "5055";
      };
    };
  };
}
