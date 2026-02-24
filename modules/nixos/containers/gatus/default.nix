{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.gatus;

  version = "5.35.0";
  gatus_config_yaml = pkgs.writeTextFile {
    name = "config.yaml";
    text = ''
      client:
        insecure: false
        ignore-redirect: false
        timeout: 10s
    '';
  };
in
{
  imports = [ inputs.nixos-thurs.nixosModules.gatus ];

  options.mine.container.gatus = {
    enable = mkEnableOption "gatus";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        "discord/monitoring/WEBHOOK_URL" = { };
        "gotify/token/GATUS" = { };
        "gotify/URL" = { };
      };
      templates."alerting.yaml".content = ''
        alerting:
          gotify:
            server-url: http://gotify
            token: ${config.sops.placeholder."gotify/token/GATUS"}
            priority: 10
          discord:
            webhook-url: ${config.sops.placeholder."discord/monitoring/WEBHOOK_URL"}
            default:
              enabled: true
              failure-threshold: 2
              success-threshold: 2
              send-on-resolved: true
              description: "healthcheck failed 2 times in a row"
      '';
    };

    environment.etc = {
      "alloy/overseerr.alloy" = mkIf config.mine.services.alloy.enable {
        text = builtins.readFile (
          pkgs.replaceVars ./config.alloy {
            host = config.networking.hostName;
          }
        );
      };
    };

    virtualisation.oci-containers.containers."gatus" = {
      image = "twinproduction/gatus:v${version}";
      hostname = "gatus";
      ports = [ "8080" ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      environment = {
        GATUS_CONFIG_PATH = "/config";
        GATUS_LOG_LEVEL = "WARN";
      };
      volumes = [
        "${gatus_config_yaml}:/config/config.yaml"
        "${config.sops.templates."alerting.yaml".path}:/config/alerting.yaml"
        "${config.nixos-thurs.gatus.endpoints}:/config/endpoints.yaml"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.gatus.tls" = "true";
        "traefik.http.routers.gatus.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.gatus.entrypoints" = "websecure";
        "traefik.http.routers.gatus.rule" = "Host(`uptime.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.gatus.loadbalancer.server.port" = "8080";
        "traefik.http.routers.gatus.middlewares" = "basic-auth";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/TwiN/gatus";
      };
    };
  };
}
