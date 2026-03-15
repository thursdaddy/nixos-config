_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "prometheus";
      version = "2.52.0";

      cfg = config.mine.containers.${name};
      fqdn = "${cfg.subdomain}.${config.mine.containers.traefik.rootDomainName}";

      prometheus_config = builtins.readFile (
        pkgs.replaceVars ./prometheus.yml {
          prom_token = config.sops.placeholder."hass/PROM_TOKEN";
        }
      );
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "Enable prometheus container";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = name;
        };
        version = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "latest";
          description = "prometheus image version";
        };
        configFile = lib.mkOption {
          type = lib.types.path;
          default = ./prometheus.yml;
          description = "prometheus config file path";
        };
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers.prometheus = {
          user = "root";
          image = "prom/prometheus:v${version}";
          hostname = "prometheus";
          ports = [
            "0.0.0.0:9090:9090"
          ];
          extraOptions = [
            "--network=traefik"
            "--pull=always"
          ];
          cmd = [
            "--config.file=/etc/prometheus/prometheus.yml"
            "--storage.tsdb.retention.size=50GB"
            "--web.enable-admin-api"
          ];
          volumes = [
            "${config.sops.templates."prometheus_config".path}:/etc/prometheus/prometheus.yml"
            "${config.mine.containers.settings.configPath}/prometheus:/prometheus"
          ];
          labels = {
            "traefik.enable" = "true";
            "traefik.http.routers.${name}.tls" = "true";
            "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
            "traefik.http.routers.${name}.entrypoints" = "websecure";
            "traefik.http.routers.${name}.rule" = "Host(`${fqdn}`)";
            "traefik.http.services.${name}.loadbalancer.server.port" = "9090";
            "enable.versions.check" = "false";
            "homelab.backup.enable" = "true";
            "homelab.backup.path" = "${config.mine.containers.settings.configPath}";
            "homelab.backup.path.ignore" = "prometheus";
            "homelab.backup.path.include" =
              "${config.mine.containers.settings.configPath}/prometheus/data/snapshots";
            "homelab.backup.retention.period" = "5";
          };
        };

        sops = {
          secrets."hass/PROM_TOKEN" = { };
          templates."prometheus_config".content = prometheus_config;
        };

        networking.firewall.allowedTCPPorts = [ 9090 ];
      };
    };
}
