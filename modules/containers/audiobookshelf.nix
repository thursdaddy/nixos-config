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
      configPath = config.mine.containers.settings.configPath;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name}.traefik.container = {
            port = 80;
            subDomain = "abs";
            tailscale = true;
          };
          nfs-mounts = {
            enable = true;
            mounts = {
              "/media/books" = {
                device = "192.168.10.12:/media/books";
              };
            };
          };
        };

        virtualisation.oci-containers.containers."${name}" = {
          image = "ghcr.io/advplyr/audiobookshelf:${version}";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          environment = {
            TZ = config.time.timeZone;
            ROUTER_BASE_PATH = "/audiobookshelf";
          };
          volumes = [
            "${configPath}/audiobookshelf/config:/config"
            "${configPath}/audiobookshelf/metadata:/metadata"
            "/media/books:/books"
          ];
          labels = {
            "org.opencontainers.image.version" = "${version}";
            "org.opencontainers.image.source" = "https://github.com/advplyr/audiobookshelf";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${configPath}/audiobookshelf";
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs name;
            };
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${config.mine.containers.settings.backend}-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
