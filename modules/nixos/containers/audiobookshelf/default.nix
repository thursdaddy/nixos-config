{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.audiobookshelf;

  version = "2.19.5";
in
{
  options.mine.container.audiobookshelf = {
    enable = mkEnableOption "audiobookshelf";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."audiobookshelf" = {
      image = "ghcr.io/advplyr/audiobookshelf:${version}";
      ports = [
        "80"
      ];
      environment = {
        TZ = "America/Phoenix";
      };
      volumes = [
        "${config.mine.container.settings.configPath}/audiobookshelf/config:/config"
        "${config.mine.container.settings.configPath}/audiobookshelf/metadata:/metadata"
        "/podcasts:/podcasts"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.audiobookshelf.tls" = "true";
        "traefik.http.routers.audiobookshelf.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.audiobookshelf.entrypoints" = "websecure";
        "traefik.http.routers.audiobookshelf.rule" = "Host(`podcasts.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.audiobookshelf.loadbalancer.server.port" = "80";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/advplyr/audiobookshelf";
      };
    };

    fileSystems."/podcasts" = {
      device = "192.168.10.12:/fast/podcasts";
      fsType = "nfs";
      options = [ "auto" "rw" "defaults" "_netdev" ];
    };
  };
}
