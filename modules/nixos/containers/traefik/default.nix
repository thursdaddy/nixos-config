{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    optionals
    types
    ;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.container.traefik;

  version = "3.5.0";

  fqdn = config.mine.container.traefik.domainName;
  regex_fqdn = builtins.replaceStrings [ "." ] [ "\\." ] "${fqdn}";
  envFileContents = ''
    AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."aws/traefik/AWS_SECRET_ACCESS_KEY"}
    AWS_ACCESS_KEY_ID=${config.sops.placeholder."aws/traefik/AWS_ACCESS_KEY_ID"}
    AWS_HOSTED_ZONE_ID=${config.sops.placeholder."aws/traefik/AWS_HOSTED_ZONE_ID"}
  '';
in
{
  options.mine.container.traefik = mkOption {
    default = { };
    type = types.submodule {
      options = {
        enable = mkEnableOption "Enable Traefik";
        dnsChallengeProvider = mkOpt types.str "route53" "Traefik dnsChallengeProvider.";
        awsEnvKeys = mkOpt types.bool false "Traefik requires keys to update route53 records.";
        domainName = mkOpt types.str "example.com" "Domain name to use with traefik";
        basicAuth = mkOpt types.bool false "enable basic auth file";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 8082 ];
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

    # used to create /etc/static/traefik, where traefik static configs are stored then mounted into traefik
    environment.etc."traefik/placeholder".text = "";

    systemd.tmpfiles.rules = [
      "d ${config.mine.container.settings.configPath}/traefik/acme 0755 root root -"
    ];

    sops = {
      secrets = {
        "aws/traefik/AWS_ACCESS_KEY_ID" = mkIf cfg.awsEnvKeys { };
        "aws/traefik/AWS_SECRET_ACCESS_KEY" = mkIf cfg.awsEnvKeys { };
        "aws/traefik/AWS_HOSTED_ZONE_ID" = mkIf cfg.awsEnvKeys { };
        "traefik/BASIC_AUTH_PASSWORD" = mkIf cfg.basicAuth { };
      };
      templates = {
        "traefik.keys.env".content = (mkIf cfg.awsEnvKeys) envFileContents;
        "userfile.env" = mkIf cfg.basicAuth {
          owner = "ssm-user";
          content = ''
            ${config.mine.user.name}:${config.sops.placeholder."traefik/BASIC_AUTH_PASSWORD"}
          '';
        };
      };
    };

    virtualisation.oci-containers.containers."traefik" = {
      image = "traefik:${version}";
      ports = [
        "0.0.0.0:80:80"
        "0.0.0.0:443:443"
        "0.0.0.0:8082:8082"
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
      volumes =
        [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
          "${config.mine.container.settings.configPath}/traefik:/etc/traefik/"
          # mounted to follow symlinks created by environment.etc for static traefik configs
          "/etc/static/traefik:/static"
          "/nix/store:/nix/store"
        ]
        ++ optionals cfg.basicAuth [
          "${config.sops.templates."userfile.env".path}:/etc/traefik/userfile"
        ];
      cmd = [
        "--api.dashboard=false"
        "--api.insecure=false"
        "--log.level=info"
        "--providers.docker=true"
        "--providers.docker.exposedbydefault=false"
        "--providers.file.directory=/static"
        "--providers.file.watch=true"
        "--entrypoints.web.address=:80"
        "--entrypoints.websecure.address=:443"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
        "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=${cfg.dnsChallengeProvider}"
        "--certificatesresolvers.letsencrypt.acme.storage=/etc/traefik/acme/acme.json"
        "--metrics.prometheus=true"
        "--metrics.prometheus.buckets=0.1,0.3,1.2,5.0"
        "--metrics.prometheus.addEntryPointsLabels=true"
        "--metrics.prometheus.addRoutersLabels=true"
        "--metrics.prometheus.addServicesLabels=true"
        "--entrypoints.metrics.address=:8082"
        "--metrics.prometheus.entrypoint=metrics"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.traefik.tls" = "true";
        "traefik.http.routers.traefik.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.traefik.tls.domains[0].main" = "${fqdn}";
        "traefik.http.routers.traefik.tls.domains[0].sans" = "*.${fqdn}";
        "traefik.http.routers.traefik.rule" = "Host(`traefik.${fqdn}`)";
        "traefik.http.routers.traefik.entrypoints" = "websecure";
        "traefik.http.routers.http-catchall.rule" = "HostRegexp(`^.+\\.${regex_fqdn}`)";
        "traefik.http.routers.http-catchall.entrypoints" = "web";
        "traefik.http.routers.http-catchall.middlewares" = "redirect-to-https@docker";
        "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme" = "https";
        "traefik.http.middlewares.basic-auth.basicauth.usersfile" = "/etc/traefik/userfile";
      };
    };
  };
}
