_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "gitlab";
      version = "18.9.1";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";

      registryName = "reg";
      registryCfg = config.mine.containers.${registryName};
      registryFqdn = "${registryCfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";
    in
    {
      options.mine.containers = {
        ${name} = {
          enable = lib.mkEnableOption "${name}";
          subdomain = lib.mkOption {
            description = "Container url";
            type = lib.types.str;
            default = "git";
          };
        };
        "${registryName}" = {
          enable = lib.mkOption {
            description = "This is for blocky to create a DNS entry";
            type = lib.types.bool;
            default = cfg.enable;
          };
          subdomain = lib.mkOption {
            description = "Gitlab Registry Container url";
            type = lib.types.str;
            default = registryName;
          };
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "gitlab/gitlab-ce:${version}-ce.0";
          hostname = "${name}";
          ports = [
            "80"
            "443"
            "0.0.0.0:2222:22"
          ];
          environment = {
            TZ = config.time.timeZone;
          };
          extraOptions = [
            "--network=traefik"
            "--pull=always"
          ];
          volumes = [
            "${config.mine.containers.settings.configPath}/gitlab/config:/etc/gitlab"
            "${config.mine.containers.settings.configPath}/gitlab/logs:/var/log/gitlab"
            "${config.mine.containers.settings.configPath}/gitlab/data:/var/opt/gitlab"
            "${config.mine.containers.settings.configPath}/gitlab/tfstate:/var/opt/gitlab/gitlab-rails/shared/terraform_state"
            "${config.mine.containers.settings.configPath}/registry/data:/var/opt/gitlab/gitlab-rails/shared/registry"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "80";
            "traefik.http.routers.${name}.service" = "gitlab";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.gitlab-registry.rule" = "Host(`${registryFqdn}`)";
            "traefik.http.routers.gitlab-registry.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.gitlab-registry.entrypoints" = "websecure";
            "traefik.http.routers.gitlab-registry.service" = "gitlab-registry";
            "traefik.http.services.gitlab-registry.loadbalancer.server.port" = "5005";
            "org.opencontainers.image.version" = "${version}";
            "org.opencontainers.image.source" = "https://github.com/gitlabhq/gitlabhq";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
            "homelab.backup.path.ignore" = "gitlab,registry";
            "homelab.backup.path.include" = "${config.mine.containers.settings.configPath}/gitlab/data/backups";
            "homelab.backup.retention.period" = "5";
          };
        };

        networking.firewall.allowedTCPPorts = [ 2222 ];

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
