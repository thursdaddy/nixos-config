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
      version = "1.36.0";

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
            image = "vaultwarden/server:${version}";
            pull = "always";
            hostname = name;
            networks = [ "traefik-${name}" ];
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
            volumes = [
              "${config.mine.containers.settings.configPath}/vaultwarden:/data"
            ];
            labels = {
              "traefik.enable" = "true";
              "traefik.docker.network" = "traefik-${name}";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
              "traefik.http.routers.${name}.entrypoints" = "tailscale";
              "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
              "traefik.http.services.${name}.loadbalancer.server.port" = "80";
              "traefik.http.routers.${name}.middlewares" = "fail2ban";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.bantime" = "3h";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.findtime" = "5m";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.maxretry" = "5";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.statuscode" = "401";
              "traefik.http.middlewares.fail2ban.plugin.fail2ban.rules.enabled" = "true";
              "homelab.backup.enable" = "true";
              "homelab.backup.path" = "${config.mine.containers.settings.configPath}/${name}";
              "homelab.backup.retention.period" = "5";
            };
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
            services = {
              "backup-${name}" = backup.service;
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
