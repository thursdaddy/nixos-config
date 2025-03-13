{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.influxdb;

  version = "2.7";
in
{
  options.mine.container.influxdb = {
    enable = mkEnableOption "influxdb";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      "influxdb/PASSWORD" = {
        owner = "thurs";
      };
      "influxdb/ADMIN_TOKEN" = {
        owner = "thurs";
      };
    };

    sops.templates."influxdb.env".content = ''
      DOCKER_INFLUXDB_INIT_PASSWORD=${config.sops.placeholder."influxdb/PASSWORD"}
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=${config.sops.placeholder."influxdb/ADMIN_TOKEN"}
    '';

    virtualisation.oci-containers.containers."influxdb" = {
      image = "influxdb:${version}";
      ports = [
        "8086"
      ];
      environment = {
        DOCKER_INFLUXDB_INIT_MODE = "setup";
        DOCKER_INFLUXDB_INIT_USERNAME = "thurs";
        DOCKER_INFLUXDB_INIT_ORG = "homelab";
        DOCKER_INFLUXDB_INIT_BUCKET = "home";
      };
      environmentFiles = [
        config.sops.templates."influxdb.env".path
      ];
      volumes = [
        "${config.mine.container.settings.configPath}/influxdb:/etc/influxdb2"
        "/mnt/data/influxdb:/var/lib/influxdb2"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.influxdb.tls" = "true";
        "traefik.http.routers.influxdb.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.influxdb.entrypoints" = "websecure";
        "traefik.http.routers.influxdb.rule" = "Host(`influx.${config.mine.container.traefik.domainName}`)";
        "traefik.http.services.influxdb.loadbalancer.server.port" = "8086";
        "org.opencontainers.image.version" = "${version}";
        "org.opencontainers.image.source" = "https://github.com/influxdata/influxdb";
      };
    };

    mine.system.nfs-mounts = {
      mounts = {
        "/mnt/data/influxdb" = {
          device = "192.168.10.12:/fast/data/influxdb";
        };
      };
    };

  };
}
