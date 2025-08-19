{ config, lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.container.syncthing;

  version = "2.0.2";
in
{
  options.mine.container.syncthing = mkOption {
    default = { };
    type = types.submodule {
      options = {
        enable = mkEnableOption "syncthing";
        subdomain = mkOpt types.str "sync" "subdomain for syncthing";
        volumePaths = mkOpt (types.listOf types.path) [ ] "List of paths for syncthing";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 22000 ];
    networking.firewall.allowedUDPPorts = [
      22000
      21027
    ];

    virtualisation.oci-containers.containers."syncthing" = {
      image = " syncthing/syncthing:${version}";
      ports = [
        "8384"
        "0.0.0.0:22000:22000/tcp"
        "0.0.0.0:22000:22000/udp"
        "0.0.0.0:21027:21027/udp"
      ];
      environment = {
        PGID = "1000";
        PUID = "1000";
      };
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/syncthing:/var/syncthing"
      ] ++ cfg.volumePaths;
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.syncthing.tls" = "true";
        "traefik.http.routers.syncthing.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.syncthing.entrypoints" = "websecure";
        "traefik.http.routers.syncthing.rule" =
          "Host(`${cfg.subdomain}.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.syncthing.loadbalancer.server.port" = "8384";
      };
    };
  };
}
