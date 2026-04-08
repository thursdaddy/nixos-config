_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "grafana";
      version = "latest";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";

      grafana_ini = pkgs.writeTextFile {
        name = "grafana.ini";
        text = builtins.readFile ./grafana.ini;
      };

      grafana_provisioning = pkgs.stdenvNoCC.mkDerivation {
        name = "grafanaProvisioning";
        src = ./provisioning;
        installPhase = ''
          mkdir $out/
          cp -Rf ./* $out/
        '';
      };

    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "Enable ${name}";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "grafana";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers.${name} = {
          image = "grafana/grafana:${version}";
          hostname = name;
          user = "1000";
          ports = [
            "3000"
          ];
          environment = {
            "GF_SERVER_DOMAIN" = "${fqdn}";
            "GF_SERVER_ROOT_URL" = "https://${fqdn}";
          };
          extraOptions = [
            "--network=traefik"
            "--pull=always"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/grafana/data:/var/lib/grafana"
            "${grafana_ini}:/etc/grafana/grafana.ini"
            "${grafana_provisioning}:/etc/grafana/provisioning/"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "3000";
            "enable.versions.check" = "false";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}/grafana/backup";
            "homelab.backup.retention.period" = "5";
          };
        };

        systemd =
          let
            backup = lib.thurs.mkBackupService {
              inherit pkgs;
              inherit name;
              extraPackages = [
                pkgs.systemd
                pkgs.rsync
              ];
              preStart = ''
                systemctl stop docker-grafana
                echo "Cleaning ${config.mine.containers.settings.configPath}/grafana/backup"
                rm -rf ${config.mine.containers.settings.configPath}/grafana/backup
                rsync -av --exclude='backup' ${config.mine.containers.settings.configPath}/grafana/data ${config.mine.containers.settings.configPath}/grafana/backup/
                systemctl start docker-grafana
                sleep 1
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
              serviceName = "docker-${name}";
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
