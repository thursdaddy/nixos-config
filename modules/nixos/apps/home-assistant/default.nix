{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.apps.home-assistant;

in
{
  options.mine.apps.home-assistant = {
    enable = mkEnableOption "Install Home-Assistant";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      appdaemon
    ];

    services.home-assistant = {
      enable = true;
      config.http.server_port = 8090;
      openFirewall = true;
      config = {
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [ "0.0.0.0/0" ];
        };
      };
    };

    sops.templates."traefik_hass_conf" = {
      owner = "thurs";
      content = ''
        http:
          routers:
            hass:
              rule: "Host(`hass2.${config.nixos-thurs.traefik.fqdn}`)"
              service: hass
              entrypoints:
                - "websecure"
              tls:
                certResolver: letsencrypt
          services:
            hass:
              loadBalancer:
                servers:
                - url: http://192.168.20.201:8090
      '';
    };

    virtualisation.oci-containers.containers."traefik" = mkIf config.mine.container.traefik.enable {
      volumes = [
        "${config.sops.templates."traefik_hass_conf".path}:/hass_conf.yml"
      ];
      cmd = [
        "--providers.file.filename=/hass_conf.yml"
      ];
    };
  };
}
