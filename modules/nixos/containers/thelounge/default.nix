{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.thelounge;
in
{
  options.mine.container.thelounge = {
    enable = mkEnableOption "thelounge IRC client";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."thelounge" = {
      image = "thelounge/thelounge:latest";
      ports = [
        "9000"
      ];
      environment = {
        PUID = "1000";
        PGID = "1000";
      };
      volumes = [
        "${config.mine.container.settings.configPath}/thelounge:/var/opt/thelounge"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.thelounge.tls" = "true";
        "traefik.http.routers.thelounge.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.thelounge.entrypoints" = "websecure";
        "traefik.http.routers.thelounge.rule" = "Host(`irc.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.thelounge.loadbalancer.server.port" = "9000";
      };
    };
  };
}
