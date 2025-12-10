{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.navidrome;

  version = "0.59.0";
in
{
  options.mine.container.navidrome = {
    enable = mkEnableOption "navidrome";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."navidrome" = {
      image = "deluan/navidrome:${version}";
      ports = [
        "4533"
      ];
      environment = {
        TZ = "America/Phoenix";
        UID = "1000";
        GID = "1000";
        ND_LOGLEVEL = "info";
      };
      volumes = [
        "${config.mine.container.settings.configPath}/navidrome/:/data"
        "/music:/music"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.navidrome.tls" = "true";
        "traefik.http.routers.navidrome.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.navidrome.entrypoints" = "websecure";
        "traefik.http.routers.navidrome.rule" = "Host(`music.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.navidrome.loadbalancer.server.port" = "4533";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/navidrome/navidrome";
      };
    };

    fileSystems."/music" = {
      device = "192.168.10.12:/media/music";
      fsType = "nfs";
      options = [
        "auto"
        "rw"
        "defaults"
        "_netdev"
      ];
    };
  };
}
