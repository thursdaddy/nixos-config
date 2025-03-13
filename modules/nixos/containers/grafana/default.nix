{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.grafana;

  version = "latest";
  grafana_ini = pkgs.writeTextFile {
    name = "grafana.ini";
    text = builtins.readFile ./grafana.ini;
  };
  grafana_provisioning = pkgs.stdenvNoCC.mkDerivation {
    name = "grafanaProvisioning";
    src = ./provisioning;
    installPhase = ''
      mkdir $out/
      cp -Rf ./* $out/
    '';
  };
in
{
  options.mine.container.grafana = {
    enable = mkEnableOption "Enable Grafana container";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.grafana = {
      user = "1000";
      image = "grafana/grafana:${version}";
      hostname = "grafana";
      ports = [
        "3000"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/grafana/data:/var/lib/grafana"
        "${grafana_ini}:/etc/grafana/grafana.ini"
        "${grafana_provisioning}:/etc/grafana/provisioning/"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.grafana.tls" = "true";
        "traefik.http.routers.grafana.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.grafana.entrypoints" = "websecure";
        "traefik.http.routers.grafana.rule" = "Host(`grafana.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.grafana.loadbalancer.server.port" = "3000";
        "enable.versions.check" = "false";
      };
    };
  };
}
