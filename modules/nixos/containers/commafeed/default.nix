{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.commafeed;

  version = "5.6.1";
in
{
  options.mine.container.commafeed = {
    enable = mkEnableOption "commafeed";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."commafeed" = {
      image = "athou/commafeed:${version}-h2";
      ports = [
        "8082"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/commafeed:/commafeed/data"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.commafeed.tls" = "true";
        "traefik.http.routers.commafeed.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.commafeed.entrypoints" = "websecure";
        "traefik.http.routers.commafeed.rule" = "Host(`feed.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.commafeed.loadbalancer.server.port" = "8082";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/Athou/commafeed";
      };
    };
  };
}
