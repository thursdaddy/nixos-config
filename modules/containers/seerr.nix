_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      name = "seerr";
      version = "3.2.0";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "request";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "${name}/${name}:v${version}";
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
            "${config.mine.containers.settings.configPath}/${name}:/app/config"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "5055";
          };
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "docker-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
