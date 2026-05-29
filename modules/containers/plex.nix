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
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "${name}";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          traefik = {
            networks = [ "traefik-${name}" ];
          };
          "${name}" = {
            image = "lscr.io/linuxserver/${name}:${version}";
            pull = "always";
            networks = [
              "${name}"
              "traefik-${name}"
            ];
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
              "${config.mine.containers.settings.configPath}/${name}:/config"
              "/media/shows:/media/shows"
              "/media/movies:/media/movies"
              "/media/youtube:/media/youtube"
              "/fast/music:/media/music"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.docker.network" = "traefik-${name}";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "32400";
            };
          };
        };

        systemd.services = {
          "init-docker-network-${name}" = {
            description = "Create Docker networks for Traefik isolation";
            after = [ "docker.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = [
                "-${lib.getExe pkgs.docker} network create traefik-${name}"
                "-${lib.getExe pkgs.docker} network create ${name}"
              ];
            };
          };
          "docker-traefik" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
          "docker-${name}" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
        };

        mine.base.nfs-mounts = {
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
