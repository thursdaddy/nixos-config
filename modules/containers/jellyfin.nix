_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "jellyfin";
      version = "10.11.10";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.nixos-thurs.publicDomain}";
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = name;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          traefik = {
            networks = [ "traefik-${name}" ];
          };
          "${name}" = {
            image = "lscr.io/linuxserver/${name}:${version}";
            hostname = name;
            pull = "always";
            networks = [
              "traefik-${name}"
              "${name}"
            ];
            ports = [
              "8096"
              "8920"
              "7359:7359/udp"
              "1900:1900/udp"
            ];
            environment = {
              JELLYFIN_PublishedServerUrl = "https://${fqdn}";
              JELLYFIN_Network__KnownProxies = "172.21.0.0/16";
              NVIDIA_DRIVER_CAPABILITIES = "all";
              NVIDIA_VISIBLE_DEVICES = "all";
              PGID = "1000";
              PUID = "1000";
              TZ = config.time.timeZone;
            };
            devices = [
              "/dev/dri:/dev/dri"
            ];
            extraOptions = [
              "--annotation=run.oci.keep_original_groups=1"
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/${name}:/config"
              "/media/shows:/media/shows:ro"
              "/media/movies:/media/movies:ro"
              "/media/youtube:/media/youtube:ro"
              "/fast/music:/media/music:ro"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.docker.network" = "traefik-${name}";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "8096";
              "traefik.http.routers.${name}.middlewares" = "fail2ban";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.bantime" = "3h";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.findtime" = "5m";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.maxretry" = "5";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.statuscode" = "401";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.enabled" = "true";
            };
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

        systemd.services = {
          docker-traefik = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
          "docker-${name}" = {
            after = [ "init-docker-network-${name}.service" ];
            requires = [ "init-docker-network-${name}.service" ];
          };
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
