{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.vaultwarden;

  version = "1.34.1";
in
{
  options.mine.container.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        "vaultwarden/YUBICO_CLIENT_ID" = { };
        "vaultwarden/YUBICO_SECRET_KEY" = { };
      };
      templates."vaultwarden.env".content = ''
        YUBICO_CLIENT_ID=${config.sops.placeholder."vaultwarden/YUBICO_CLIENT_ID"}
        YUBICO_SECRET_KEY=${config.sops.placeholder."vaultwarden/YUBICO_SECRET_KEY"}
      '';
    };

    environment.etc."alloy/vaultwarden.alloy" = mkIf config.mine.services.alloy.enable {
      text = builtins.readFile ./config.alloy;
    };

    virtualisation.oci-containers.containers."vaultwarden" = {
      image = "vaultwarden/server:${version}";
      hostname = "vaultwarden";
      ports = [ "80" ];
      environment = {
        DOMAIN = "https://bw.${config.mine.container.traefik.domainName}";
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
        "${config.mine.container.settings.configPath}/vaultwarden:/data"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.vaultwarden.tls" = "true";
        "traefik.http.routers.vaultwarden.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.vaultwarden.entrypoints" = "websecure";
        "traefik.http.routers.vaultwarden.rule" = "Host(`bw.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.vaultwarden.loadbalancer.server.port" = "80";
      };
    };
  };
}
