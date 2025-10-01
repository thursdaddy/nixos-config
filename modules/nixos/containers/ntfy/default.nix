{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.ntfy;

  version = "2.11.0";
  ntfy_conf = pkgs.writeTextFile {
    name = "server.yml";
    text = builtins.readFile (
      pkgs.replaceVars ./server.yml {
        domain = config.mine.container.traefik.domainName;
      }
    );
  };
in
{
  options.mine.container.ntfy = {
    enable = mkEnableOption "ntfy";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."ntfy" = {
      image = "binwiederhier/ntfy:v${version}";
      hostname = "ntfy";
      ports = [
        "80"
        "0.0.0.0:9090:9090"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/ntfy/cache:/var/cache/ntfy"
        "${config.mine.container.settings.configPath}/ntfy:/etc/ntfy"
        "${ntfy_conf}:/etc/ntfy/server.yml"
      ];
      environment = {
        TZ = config.mine.system.timezone.location;
      };
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      cmd = [ "serve" ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.ntfy.tls" = "true";
        "traefik.http.routers.ntfy.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.ntfy.entrypoints" = "websecure";
        "traefik.http.routers.ntfy.rule" = "Host(`ntfy.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.ntfy.loadbalancer.server.port" = "80";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/binwiederhier/ntfy";
      };
    };
  };
}
