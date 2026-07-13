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

      prometheus_config = builtins.readFile (
        pkgs.replaceVars ./prometheus.yml {
          prom_token = config.sops.placeholder."hass/PROM_TOKEN";
        }
      );

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
