_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "audiobookshelf";
      version = "2.33.2";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "podcasts";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "ghcr.io/advplyr/audiobookshelf:${version}";
          ports = [
            "80"
          ];
          environment = {
            TZ = config.time.timeZone;
          };
          volumes = [
            "${config.mine.containers.settings.configPath}/audiobookshelf/config:/config"
            "${config.mine.containers.settings.configPath}/audiobookshelf/metadata:/metadata"
            "/podcasts:/podcasts"
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
            "traefik.http.services.${name}.loadbalancer.server.port" = "80";
            "org.opencontainers.image.version" = "${version}";
            "org.opencontainers.image.source" = "https://github.com/advplyr/audiobookshelf";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
            "homelab.backup.retention.period" = "5";
          };
        };

        fileSystems."/podcasts" = {
          device = "192.168.10.12:/fast/podcasts";
          fsType = "nfs";
          options = [
            "auto"
            "rw"
            "defaults"
            "_netdev"
          ];
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
