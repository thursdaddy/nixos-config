_: {
  flake.modules.nixos.services =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "victoriametrics";
      cfg = config.mine.services.${name};
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkEnableOption "Enable VictoriaMetrics service";
        retentionPeriod = lib.mkOption {
          type = lib.types.str;
          default = "10y";
          description = "Retention period for VictoriaMetrics";
        };
        scrapeConfig = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = builtins.readFile ./victoriametrics_system.yml;
          description = "Custom Prometheus scrape configuration content. If null, VictoriaMetrics will not scrape anything.";
        };
        subDomain = lib.mkOption {
          type = lib.types.str;
          default = "vm-hass";
          description = "Subdomain for VictoriaMetrics Traefik route";
        };
      };

      config = lib.mkIf cfg.enable {
        services.victoriametrics = {
          enable = true;
          retentionPeriod = cfg.retentionPeriod;
          extraOptions = lib.mkIf (cfg.scrapeConfig != null) [
            "-promscrape.config=${config.sops.templates."victoriametrics_config".path}"
          ];
        };

        sops = {
          secrets = {
            "hass/PROM_TOKEN" = { };
          };
          templates = lib.mkIf (cfg.scrapeConfig != null) {
            "victoriametrics_config" = {
              content = cfg.scrapeConfig;
              mode = "0444";
            };
          };
        };

        networking.firewall.allowedTCPPorts = [ 8428 ];

        mine.homelab.${config.networking.hostName} = {
          apps.victoriametrics = {
            traefik.static.victoriametrics = {
              port = 8428;
              subDomain = cfg.subDomain;
            };
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs;
              name = "backup-${name}";
              extraEnv = {
                HOMELAB_BACKUP_ENABLE = "true";
                HOMELAB_BACKUP_PATH = "/var/lib/victoriametrics/snapshots/current_backup";
                HOMELAB_BACKUP_RSYNC_COPY_UNSAFE_LINKS = "true";
              };
              extraPackages = [
                pkgs.curl
                pkgs.jq
              ];
              preStart = ''
                # Clean old backups
                rm -rf /var/lib/victoriametrics/snapshots/current_backup || true

                # Trigger snapshot
                res=$(curl -sS http://localhost:8428/snapshot/create)
                snap_id=$(echo "$res" | ${pkgs.jq}/bin/jq -r .snapshot)

                # Move to current_backup
                mv "/var/lib/victoriametrics/snapshots/$snap_id" /var/lib/victoriametrics/snapshots/current_backup
              '';
              postStart = ''
                # Clean up local snapshots
                curl -sS http://localhost:8428/snapshot/delete_all
              '';
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
              serviceName = name;
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
