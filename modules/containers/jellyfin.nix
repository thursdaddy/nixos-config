_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      name = "jellyfin";
      version = "10.11.10";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;

      subdomain = "jellyfin";
      fqdn = "${subdomain}.${config.mine.homelab.${config.networking.hostName}.rootDomainName}";
    in
    {
      options.mine.containers."${name}" = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.${name} = {
            traefik = {
              domain = config.nixos-thurs.publicDomain;
              container = {
                port = 8096;
              };
            };
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
            hostname = name;
            ports = [
              "8920"
              "7359:7359/udp"
              "1900:1900/udp"
            ];
            environment = {
              DOCKER_MODS = "linuxserver/mods:jellyfin-opencl-intel";
              JELLYFIN_PublishedServerUrl = "https://${fqdn}";
              JELLYFIN_Network__KnownProxies = "10.89.8.0/24";
              PGID = "1000";
              PUID = "1000";
              TZ = config.time.timeZone;
            };
            devices = [
              "/dev/dri:/dev/dri"
            ];
            extraOptions = [
              "--group-add=303"
              "--userns=keep-id"
            ];
            volumes = [
              "${configPath}/${name}:/config"
              "/media/shows:/media/shows:ro"
              "/media/movies:/media/movies:ro"
              "/media/youtube:/media/youtube:ro"
              "/media/music:/media/music:ro"
            ];
            labels = {
              "traefik.http.routers.${name}.middlewares" = "fail2ban,jellyfin-sec";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.bantime" = "3h";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.findtime" = "5m";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.maxretry" = "5";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.statuscode" = "401";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.enabled" = "true";
              "traefik.http.middlewares.jellyfin-sec.headers.customResponseHeaders.X-Robots-Tag" =
                "noindex,nofollow,nosnippet,noarchive,notranslate,noimageindex";
              "traefik.http.middlewares.jellyfin-sec.headers.STSSeconds" = "315360000";
              "traefik.http.middlewares.jellyfin-sec.headers.STSIncludeSubdomains" = "true";
              "traefik.http.middlewares.jellyfin-sec.headers.STSPreload" = "true";
              "traefik.http.middlewares.jellyfin-sec.headers.forceSTSHeader" = "true";
              "traefik.http.middlewares.jellyfin-sec.headers.contentTypeNosniff" = "true";
              "traefik.http.middlewares.jellyfin-sec.headers.customresponseheaders.X-XSS-PROTECTION" = "1";
              "traefik.http.middlewares.jellyfin-sec.headers.customFrameOptionsValue" = "SAMEORIGIN";
            };
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
