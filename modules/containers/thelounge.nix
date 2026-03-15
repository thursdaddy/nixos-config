_: {
  flake.modules.nixos.containers =
    { config, lib, ... }:
    let
      name = "thelounge";
      cfg = config.mine.containers.${name};

      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "thelounge IRC client";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "irc";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "thelounge/thelounge:latest";
          ports = [
            "9000"
          ];
          environment = {
            PUID = "1000";
            PGID = "1000";
          };
          volumes = [
            "${config.mine.containers.settings.configPath}/thelounge:/var/opt/thelounge"
          ];
          extraOptions = [
            "--network=traefik"
            "--pull=always"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "9000";
          };
        };
      };
    };
}
