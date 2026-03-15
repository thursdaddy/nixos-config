_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      ...
    }:
    let
      name = "vaultwarden";
      version = "1.35.4";

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
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
            "homelab.backup.retention.period" = "5";
          };
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
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
