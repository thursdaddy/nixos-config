_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "plex";
      version = "1.43.2";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik.container.port = 32400;
          };
          nfs-mounts = {
            enable = true;
            mounts = {
              "/media/shows" = {
                device = "192.168.10.12:/media/shows";
              };
              "/media/movies" = {
                device = "192.168.10.12:/media/movies";
              };
              "/media/music" = {
                device = "192.168.10.12:/fast/music";
              };
              "/media/youtube" = {
                device = "192.168.10.12:/media/youtube";
              };
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "lscr.io/linuxserver/${name}:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            ports = [
              "32400:32400"
              "5353:5353/udp"
              "8324:8324"
              "32410:32410/udp"
              "32412:32412/udp"
              "32413:32413/udp"
              "32414:32414/udp"
              "32469:32469"
            ];
            environment = {
              PUID = "1000";
              PGID = "1000";
              TZ = config.time.timeZone;
              VERSION = "docker";
            };
            devices = [
              "/dev/dri:/dev/dri"
            ];
            volumes = [
              "${configPath}/${name}:/config"
              "/media/shows:/media/shows"
              "/media/movies:/media/movies"
              "/media/youtube:/media/youtube"
              "/media/music:/media/music"
            ];
          };
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
