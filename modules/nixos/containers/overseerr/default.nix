{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.overseerr;

  version = "1.35.0";
in
{
  options.mine.container.overseerr = {
    enable = mkEnableOption "overseerr";
  };

  config = mkIf cfg.enable {
    environment.etc = {
      "alloy/overseerr.alloy" = mkIf config.mine.services.alloy.enable {
        text = builtins.readFile (
          pkgs.replaceVars ./config.alloy {
            host = config.networking.hostName;
          }
        );
      };
    };

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
        "homelab.backup.enable" = "true";
        "homelab.backup.path" = "${config.mine.container.settings.configPath}";
        "homelab.backup.retention.period" = "5";
      };
    };
  };
}
