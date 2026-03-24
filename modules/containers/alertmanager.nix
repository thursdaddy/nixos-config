_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
      name = "alertmanager";
      version = "0.31.0";
      port = "9093";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "Enable ${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = name;
        };
        version = lib.mkOption {
          description = "Container version";
          type = lib.types.str;
          default = version;
        };
      };
      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers.${name} = {
          image = "prom/alertmanager:v${cfg.version}";
          hostname = name;
          ports = [
            port
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/${name}:/alertmanager/data"
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
            "traefik.http.services.${name}.loadbalancer.server.port" = "${port}";
            "org.opencontainers.image.version" = "${cfg.version}";
            "org.opencontainers.image.source" = "https://github.com/prometheus/alertmanager";
          };
        };
      };
    };
}
