{ inputs, ... }:
{
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
      allConfigs = inputs.self.nixosConfigurations or { };

      defaultScrapeConfig =
        let
          includedHosts = [
            "c137"
            "homebox"
            "jupiter"
            "kepler"
            "netpi1"
            "netpi2"
            "printpi"
            "streambox"
            "wormhole"
            "gcloudbox"
            "cloudbox"
          ];

          targetConfigs = lib.filterAttrs (
            hostName: hostValue: (builtins.elem hostName includedHosts) && (hostValue ? config)
          ) allConfigs;

          getHostTarget = hostName: port:
            let
              hostCfg = targetConfigs.${hostName}.config.mine.homelab.${hostName} or { };
              tailscaleIp = hostCfg.tailscaleIp or "";
              hostIp = hostCfg.hostIp or "";
              ip =
                if hostName == "cloudbox" || hostName == "gcloudbox" then
                  if tailscaleIp != "" then tailscaleIp else "${hostName}.thurs.pw"
                else if hostIp != "" then
                  hostIp
                else
                  "${hostName}.thurs.pw";
            in
            "${ip}:${toString port}";

          nodeTargets = lib.mapAttrsToList (hostName: hostValue: {
            targets = [ (getHostTarget hostName 9100) ];
            labels = { instance = hostName; };
          }) (lib.filterAttrs (hostName: hostValue:
            hostValue.config.services.prometheus.exporters.node.enable or false
          ) targetConfigs);

          smartctlTargets = lib.mapAttrsToList (hostName: hostValue: {
            targets = [ (getHostTarget hostName 9633) ];
            labels = { instance = hostName; };
          }) (lib.filterAttrs (hostName: hostValue:
            hostValue.config.services.prometheus.exporters.smartctl.enable or false
          ) targetConfigs);

          zfsTargets = lib.mapAttrsToList (hostName: hostValue: {
            targets = [ (getHostTarget hostName 9134) ];
            labels = { instance = hostName; };
          }) (lib.filterAttrs (hostName: hostValue:
            hostValue.config.services.prometheus.exporters.zfs.enable or false
          ) targetConfigs);

          blockyHosts = lib.filterAttrs (hostName: hostValue:
            hostValue.config.services.blocky.enable or false
          ) targetConfigs;

          blockyJobs = lib.mapAttrsToList (hostName: hostValue: {
            job_name = "blocky-${hostName}";
            static_configs = [
              {
                targets = [ (getHostTarget hostName 4000) ];
                labels = { instance = hostName; };
              }
            ];
          }) blockyHosts;

          hasTraefik = hostValue:
            (hostValue.config.services.traefik.enable or false) ||
            (hostValue.config.mine.services.traefik.enable or false) ||
            (hostValue.config.mine.containers.traefik.enable or false);

          traefikHosts = lib.filterAttrs (hostName: hostValue: hasTraefik hostValue) targetConfigs;

          traefikJobs = lib.mapAttrsToList (hostName: hostValue: {
            job_name = "traefik-${hostName}";
            static_configs = [
              {
                targets = [ (getHostTarget hostName 8082) ];
                labels = { instance = hostName; };
              }
            ];
          }) traefikHosts;

          hasCrowdsec = hostValue:
            hostValue.config.mine.containers.crowdsec.enable or false;

          crowdsecHosts = lib.filterAttrs (hostName: hostValue: hasCrowdsec hostValue) targetConfigs;

          crowdsecJobs = lib.mapAttrsToList (hostName: hostValue: {
            job_name = "crowdsec-${hostName}";
            static_configs = [
              {
                targets = [ (getHostTarget hostName 6060) ];
                labels = { instance = hostName; };
              }
            ];
          }) crowdsecHosts;

          vmTargets = lib.mapAttrsToList (hostName: hostValue: {
            targets = [ (getHostTarget hostName 8428) ];
            labels = { instance = hostName; };
          }) (lib.filterAttrs (hostName: hostValue:
            hostValue.config.services.victoriametrics.enable or false
          ) targetConfigs);

          lokiTargets = lib.mapAttrsToList (hostName: hostValue: {
            targets = [ (getHostTarget hostName 3100) ];
            labels = { instance = hostName; };
          }) (lib.filterAttrs (hostName: hostValue:
            hostValue.config.services.loki.enable or false
          ) targetConfigs);

          alloyTargets = lib.mapAttrsToList (hostName: hostValue: {
            targets = [ (getHostTarget hostName 12346) ];
            labels = { instance = hostName; };
          }) (lib.filterAttrs (hostName: hostValue:
            hostValue.config.services.alloy.enable or false
          ) targetConfigs);

          yamlVal = {
            scrape_configs = [
              {
                job_name = "node";
                static_configs = nodeTargets;
              }
            ] ++ (lib.optionals (smartctlTargets != [ ]) [
              {
                job_name = "smartctl";
                static_configs = smartctlTargets;
              }
            ]) ++ (lib.optionals (zfsTargets != [ ]) [
              {
                job_name = "zfs";
                static_configs = zfsTargets;
              }
            ]) ++ (lib.optionals (vmTargets != [ ]) [
              {
                job_name = "victoriametrics";
                static_configs = vmTargets;
              }
            ]) ++ (lib.optionals (lokiTargets != [ ]) [
              {
                job_name = "loki";
                static_configs = lokiTargets;
              }
            ]) ++ (lib.optionals (alloyTargets != [ ]) [
              {
                job_name = "alloy";
                static_configs = alloyTargets;
              }
            ]) ++ blockyJobs ++ traefikJobs ++ crowdsecJobs;
          };
        in
        lib.generators.toYAML { } yamlVal;
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
          default = defaultScrapeConfig;
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
