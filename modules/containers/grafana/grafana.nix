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
      configPath = config.mine.containers.settings.configPath;
      ociBackend =
        if config.mine.containers.settings.backend == "podman" then
          "podman"
        else if config.mine.containers.settings.backend == "docker" then
          "docker"
        else
          "";

      traefikCfg = config.mine.homelab.${config.networking.hostName}.apps.${name}.traefik;
      fqdn = "${traefikCfg.container.subDomain}.${traefikCfg.domain}";

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
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.grafana = {
            traefik.container.port = 3000;
          };
        };

        virtualisation.oci-containers.containers.${name} = {
          image = "grafana/grafana:${version}";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          hostname = name;
          user = "1000";
          environment = {
            GF_SERVER_DOMAIN = "${fqdn}";
            GF_SERVER_ROOT_URL = "https://${fqdn}";
            TZ = config.time.timeZone;
          };
          volumes = [
            "${configPath}/grafana/data:/var/lib/grafana"
            "${grafana_ini}:/etc/grafana/grafana.ini"
            "${grafana_provisioning}:/etc/grafana/provisioning/"
          ];
          labels = {
            "enable.versions.check" = "false";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${configPath}/grafana/backup";
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
                systemctl stop ${ociBackend}-grafana
                echo "Cleaning ${configPath}/grafana/backup"
                rm -rf ${configPath}/grafana/backup
                rsync -av --exclude='backup' ${configPath}/grafana/data ${configPath}/grafana/backup/
                systemctl start ${ociBackend}-grafana
                sleep 15
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
