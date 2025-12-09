{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.gitlab;

  version = "18.6.1";
in
{
  options.mine.container.gitlab = {
    enable = mkEnableOption "gitlab";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 2222 ];

    virtualisation.oci-containers.containers."gitlab" = {
      image = "gitlab/gitlab-ce:${version}-ce.0";
      ports = [
        "80"
        "443"
        "0.0.0.0:2222:22"
      ];
      environment = {
        TZ = "America/Phoenix";
      };
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/gitlab/config:/etc/gitlab"
        "${config.mine.container.settings.configPath}/gitlab/logs:/var/log/gitlab"
        "${config.mine.container.settings.configPath}/gitlab/data:/var/opt/gitlab"
        "${config.mine.container.settings.configPath}/gitlab/tfstate:/var/opt/gitlab/gitlab-rails/shared/terraform_state"
        "${config.mine.container.settings.configPath}/registry/data:/var/opt/gitlab/gitlab-rails/shared/registry"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.gitlab.rule" = "Host(`git.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.gitlab.loadbalancer.server.port" = "80";
        "traefik.http.routers.gitlab.service" = "gitlab";
        "traefik.http.routers.gitlab.entrypoints" = "websecure";
        "traefik.http.routers.gitlab.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.gitlab-registry.rule" =
          "Host(`reg.${config.mine.container.traefik.domainName}`)";
        "traefik.http.routers.gitlab-registry.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.gitlab-registry.entrypoints" = "websecure";
        "traefik.http.routers.gitlab-registry.service" = "gitlab-registry";
        "traefik.http.services.gitlab-registry.loadbalancer.server.port" = "5005";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/gitlabhq/gitlabhq";
        "homelab.backup.enable" = "true";
        "homelab.backup.path" = "${config.mine.container.settings.configPath}";
        "homelab.backup.path.ignore" = "gitlab,registry";
        "homelab.backup.path.include" = "${config.mine.container.settings.configPath}/gitlab/data/backups";
        "homelab.backup.retention.period" = "5";
      };
    };
  };
}
