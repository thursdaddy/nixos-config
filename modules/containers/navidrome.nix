_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "navidrome";
      version = "0.61.2";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "music";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "deluan/navidrome:${version}";
            ports = [
              "4533"
            ];
            volumes = [
              "/mnt/music:/music"
              "${config.mine.containers.settings.configPath}/${name}/data:/data"
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
              "traefik.http.services.${name}.loadbalancer.server.port" = "4533";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/navidrome/navidrome";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
              "homelab.backup.retention.period" = "5";
            };
          };
        };

        fileSystems."/mnt/music" = {
          device = "192.168.10.12:/fast/music";
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
