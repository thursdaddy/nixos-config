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
      version = "1.35.6";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers.vaultwarden = {
        enable = lib.mkEnableOption "vaultwarden";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = "bw";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "vaultwarden/server:${version}";
          hostname = name;
          ports = [ "80" ];
          environment = {
            DOMAIN = "https://${fqdn}";
            SIGNUPS_ALLOWED = "false";
            INVITATIONS_ALLOWED = "false";
            SHOW_PASSWORD_HINT = "false";
          };
          environmentFiles = [
            config.sops.templates."vaultwarden.env".path
          ];
          extraOptions = [
            "--network=traefik"
            "--pull=always"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/vaultwarden:/data"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "80";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}";
            "homelab.backup.retention.period" = "5";
          };
        };

        systemd =
          let
            hostJupiter = lib.optionalAttrs (config.networking.hostName == "jupiter") {
              extraPackages = [ pkgs.rsync ];
              preStart = ''
                rsync -avz --delete \
                -e "${pkgs.openssh}/bin/ssh -i /home/thurs/.ssh/cloudbox -o StrictHostKeyChecking=no" \
                thurs@cloudbox:/opt/configs/vaultwarden /opt/configs/
              '';
            };

            backup = lib.thurs.mkBackupService ({
              inherit pkgs name;
              extraPackages = [
                pkgs.docker-client
              ]
              ++ (hostJupiter.extraPackages or [ ]);
              preStart = (hostJupiter.preStart or "") + ''
                docker exec -t vaultwarden find /data -type f -iname "db_*" -mtime +3 -exec rm -v {} \;
                docker exec -t vaultwarden /vaultwarden backup
              '';
            });
          in
          {
            services."backup-${name}" = backup.service;
            timers."backup-${name}" = backup.timer;
          };

        sops = {
          secrets = {
            "vaultwarden/YUBICO_CLIENT_ID" = { };
            "vaultwarden/YUBICO_SECRET_KEY" = { };
            "vaultwarden/ADMIN_TOKEN" = { };
          };
          templates."vaultwarden.env".content = ''
            YUBICO_CLIENT_ID=${config.sops.placeholder."vaultwarden/YUBICO_CLIENT_ID"}
            YUBICO_SECRET_KEY=${config.sops.placeholder."vaultwarden/YUBICO_SECRET_KEY"}
            ADMIN_TOKEN=${config.sops.placeholder."vaultwarden/ADMIN_TOKEN"}
          '';
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
