# wip
_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      name = "pinchflat";
      musicName = "pinchflat-music";
      version = "2025.9.26";
      # The maintainer only publishes container as latest but I
      # still want the docker version checker script to work.
      tag = "latest";

      cfg = config.mine.containers.${name};
      cfgMusic = config.mine.containers.${musicName};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers = {
        "${name}" = {
          enable = lib.mkEnableOption "${name}";
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = name;
          };
        };
        "${musicName}" = {
          enable = lib.mkEnableOption "${musicName}";
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = musicName;
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfgMusic.enable {
          virtualisation.oci-containers.containers.${musicName} = {
            image = "ghcr.io/kieraneglin/${name}:${tag}";
            hostname = musicName;
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            ports = [
              "8945"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/pinchflat/music:/config/"
              "/mnt/music/youtube/:/downloads/"
            ];
            extraOptions = [
              "--network=traefik"
            ];
            environment = {
              TZ = config.time.timeZone;
            };
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${musicName}.tls" = "true";
              "traefik.http.routers.${musicName}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${musicName}.entrypoints" = "websecure";
              "traefik.http.routers.${musicName}.rule" =
                "Host(`${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}`)";
              "traefik.http.services.${musicName}.loadbalancer.server.port" = "8945";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/kieraneglin/pinchflat";
            };
          };

          environment.etc =
            let
              alloyJournalMusic = lib.thurs.mkAlloyJournal {
                name = musicName;
                serviceName = "${config.mine.containers.settings.backend}-${name}";
              };
            in
            builtins.listToAttrs [
              alloyJournalMusic
            ];

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
        })

        (lib.mkIf cfg.enable {
          virtualisation.oci-containers.containers.${name} = {
            image = "ghcr.io/kieraneglin/${name}:${tag}";
            hostname = name;
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            ports = [
              "8945"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/pinchflat/youtube:/config/"
              "/mnt/youtube/:/downloads/"
            ];
            extraOptions = [
              "--network=traefik"
            ];
            environment = {
              TZ = config.time.timeZone;
            };
            labels = {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "8945";
              "org.opencontainers.image.version" = "${version}";
              "org.opencontainers.image.source" = "https://github.com/kieraneglin/pinchflat";
            };
          };

          environment.etc =
            let
              alloyJournal = lib.thurs.mkAlloyJournal {
                inherit name;
                serviceName = "${config.mine.containers.settings.backend}-${name}";
              };
            in
            builtins.listToAttrs [
              alloyJournal
            ];

          fileSystems."/mnt/youtube" = lib.mkIf cfg.enable {
            device = "192.168.10.12:/media/youtube";
            fsType = "nfs";
            options = [
              "auto"
              "rw"
              "defaults"
              "_netdev"
            ];
          };
        })
      ];
    };
}
