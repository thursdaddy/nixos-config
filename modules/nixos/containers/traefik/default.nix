{ config, lib, pkgs, inputs, ... }:
let

  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.container.traefik;
  traefik_cfg = config.nixos-thurs.traefik;
  regex_fqdn = builtins.replaceStrings [ "." ] [ "\\." ] "${traefik_cfg.fqdn}";


  version = "3.3.3";

  envFileContents = ''
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."aws/traefik/AWS_SECRET_ACCESS_KEY"}
    AWS_ACCESS_KEY_ID=${config.sops.placeholder."aws/traefik/AWS_ACCESS_KEY_ID"}
    AWS_HOSTED_ZONE_ID=${config.sops.placeholder."aws/traefik/AWS_HOSTED_ZONE_ID"}
  '';

in
{
  imports = [ inputs.nixos-thurs.nixosModules.traefik ];

  options.mine.container.traefik = mkOption {
    default = { };
    type = types.submodule {
      options = {
        enable = mkEnableOption "Enable Traefik";
        version = mkOpt types.str "v${version}" "Traefik image version";
        dnsChallengeProvider = mkOpt types.str "route53" "Traefik dnsChallengeProvider.";
        awsEnvKeys = mkOpt types.bool false "Traefik requires keys to update route53 records.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.create-traefik-network = {
      description = "Create Traefik network after docker is running";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "3s";
      };
      script = ''
        if ${pkgs.docker}/bin/docker ps >/dev/null 2>&1; then
          ${pkgs.docker}/bin/docker network inspect traefik >/dev/null 2>&1 ||\
          ${pkgs.docker}/bin/docker network create -d bridge traefik
        fi
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${config.mine.container.configPath}/traefik/acme 0755 root root -"
    ];

    sops = {
      secrets = {
        "aws/traefik/AWS_ACCESS_KEY_ID" = mkIf cfg.awsEnvKeys { };
        "aws/traefik/AWS_SECRET_ACCESS_KEY" = mkIf cfg.awsEnvKeys { };
        "aws/traefik/AWS_HOSTED_ZONE_ID" = mkIf cfg.awsEnvKeys { };
      };
      templates."traefik.keys.env".content = (mkIf cfg.awsEnvKeys) envFileContents;
    };

    virtualisation.oci-containers.containers."traefik" = {
      image = "traefik:${cfg.version}";
      ports = [
        "0.0.0.0:80:80"
        "0.0.0.0:443:443"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      environmentFiles = mkIf cfg.awsEnvKeys [
        config.sops.templates."traefik.keys.env".path
      ];
      environment = {
        AWS_REGION = "us-west-2";
      };
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "${config.mine.container.configPath}/traefik:/etc/traefik/"
      ];
      cmd = [
        "--api.dashboard=false"
        "--api.insecure=false"
        "--log.level=info"
        "--providers.docker=true"
        "--providers.docker.exposedbydefault=false"
        "--entrypoints.web.address=:80"
        "--entrypoints.websecure.address=:443"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=${cfg.dnsChallengeProvider}"
        "--certificatesresolvers.letsencrypt.acme.email=${traefik_cfg.email}"
        "--certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme/acme.json"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.traefik.tls" = "true";
        "traefik.http.routers.traefik.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.traefik.tls.domains[0].main" = "${traefik_cfg.fqdn}";
        "traefik.http.routers.traefik.tls.domains[0].sans" = "*.${traefik_cfg.fqdn}";
        "traefik.http.routers.traefik.rule" = "Host(`traefik.${traefik_cfg.fqdn}`)";
        "traefik.http.routers.traefik.entrypoints" = "websecure";
        "traefik.http.services.traefik.loadbalancer.server.port" = "8080";
        "traefik.http.routers.http-catchall.rule" = "HostRegexp(`^.+\\.${regex_fqdn}`)";
        "traefik.http.routers.http-catchall.entrypoints" = "web";
        "traefik.http.routers.http-catchall.middlewares" = "redirect-to-https@docker";
        "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme" = "https";
      };
    };
  };
}
