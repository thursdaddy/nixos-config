_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "prometheus";
      version = "2.52.0";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
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
                job_name = "hass";
                scrape_interval = "60s";
                metrics_path = "/api/prometheus";
                authorization = {
                  credentials = "@prom_token@";
                };
                scheme = "https";
                static_configs = [
                  { targets = [ "home.thurs.pw" ]; }
                ];
              }
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

      prometheus_config =
        if cfg.configFile != null then
          builtins.readFile (
            pkgs.replaceVars cfg.configFile {
              prom_token = config.sops.placeholder."hass/PROM_TOKEN";
            }
          )
        else
          builtins.replaceStrings [ "@prom_token@" ] [ config.sops.placeholder."hass/PROM_TOKEN" ] defaultScrapeConfig;

    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "Enable prometheus container";
        version = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "latest";
          description = "prometheus image version";
        };
        configFile = lib.mkOption {
          type = lib.types.path;
          default = ./prometheus.yml;
          description = "prometheus config file path";
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.prometheus = {
            traefik.container.port = 9090;
          };
        };

        virtualisation.oci-containers.containers.prometheus = {
          user = "root";
          image = "prom/prometheus:v${version}";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          ports = [
            "0.0.0.0:9090:9090"
          ];
          cmd = [
            "--config.file=/etc/prometheus/prometheus.yml"
            "--storage.tsdb.retention.size=50GB"
            "--web.enable-admin-api"
          ];
          volumes = [
            "${config.sops.templates."prometheus_config".path}:/etc/prometheus/prometheus.yml"
            "${configPath}/prometheus:/prometheus"
          ];
          labels = {
            "enable.versions.check" = "false";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${configPath}/prometheus/data/snapshots/current_backup";
          };
        };

        sops = {
          secrets."hass/PROM_TOKEN" = { };
          templates."prometheus_config".content = prometheus_config;
        };

        networking.firewall.allowedTCPPorts = [ 9090 ];

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs;
              inherit name;
              extraPackages = [
                pkgs.docker-client
                pkgs.curl
              ];
              # delete old snapshots, create new
              preStart = ''
                docker exec -t prometheus find /prometheus/data/snapshots/ -mindepth 1 -maxdepth 1 -exec rm -rf {} \; || true
                curl -sS -XPOST http://localhost:9090/api/v1/admin/tsdb/snapshot
                docker exec -t prometheus sh -c 'mv /prometheus/data/snapshots/20* /prometheus/data/snapshots/current_backup'
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
              serviceName = "${config.mine.containers.settings.backend}-${name}";
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
