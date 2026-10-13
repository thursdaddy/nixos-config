_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "vaultwarden";
      version = "1.37.3";

      cfg = config.mine.containers.${name};
      traefikCfg = config.mine.homelab.${hostName}.apps.${name}.traefik;
      hostName = config.networking.hostName;
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "${name}";
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${hostName} = {
          apps.${name} = {
            traefik.container = {
              tailscale = true;
              subDomain = "bw";
              port = 80;
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "vaultwarden/server:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            hostname = name;
            networks = [ "traefik-${name}" ];
            environment = {
              DOMAIN = "https://${traefikCfg.container.subDomain}.${traefikCfg.domain}";
              SIGNUPS_ALLOWED = "false";
              INVITATIONS_ALLOWED = "false";
              SHOW_PASSWORD_HINT = "false";
            };
            environmentFiles = [
              config.sops.templates."vaultwarden.env".path
            ];
            volumes = [
              "${config.mine.containers.settings.configPath}/vaultwarden:/data"
            ];
            labels = {
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}";
            };
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService ({
              inherit pkgs name;
              extraPackages = [
                pkgs.docker-client
              ];
              preStart = ''
                docker exec -t vaultwarden find /data -type f -iname "db_*" -delete || true
                docker exec -t vaultwarden /vaultwarden backup
                docker exec -t vaultwarden sh -c 'mv /data/db_*.sqlite3 /data/db_backup.sqlite3 2>/dev/null || true'
              '';
            });
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        sops = {
          secrets = {
            "vaultwarden/ADMIN_TOKEN" = { };
          };
          templates."vaultwarden.env".content = ''
            ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/ADMIN_TOKEN"}
          '';
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "podman-${name}";
            };
            alloyJournalBackup = lib.thurs.mkAlloyJournal {
              name = "backup-${name}";
              serviceName = "backup-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
            "${alloyJournalBackup.name}" = alloyJournalBackup.value;
          };
      };
    };
}
