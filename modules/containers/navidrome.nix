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
        tailscaleEntrypoint = lib.mkOption {
          description = "Set traefik entrypoint to tailscale Ip";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers = {
          traefik = {
            networks = [ "traefik-${name}" ];
          };
          "${name}" = {
            image = "deluan/navidrome:${version}";
            pull = "always";
            networks = [
              "${name}"
              "traefik-${name}"
            ];
            ports = [
              "4533"
            ];
            volumes = [
              "/mnt/music:/music"
              "${config.mine.containers.settings.configPath}/${name}/data:/data"
            ];
            environment = {
              ND_SCANNER_PURGEMISSING = "always";
            };
            labels = {
              "traefik.enable" = "true";
              "traefik.docker.network" = "traefik-${name}";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "tailscale";
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
          docker-traefik = {
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
            "/mnt/music" = {
              device = "192.168.10.12:/fast/music";
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
