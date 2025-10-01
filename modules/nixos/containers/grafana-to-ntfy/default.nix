{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.grafana-to-ntfy;

  rocket_toml = pkgs.writeTextFile {
    name = "rocket_toml";
    text = '''';
  };
in
{
  options.mine.container.grafana-to-ntfy = {
    enable = mkEnableOption "grafana-to-ntfy";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets = {
        "ntfy/USER" = { };
        "ntfy/URL" = { };
        "ntfy/PASSWORD" = { };
        "ntfy/topics/TESLA" = { };
        "ntfy/topics/AUDIOBOOKSHELF" = { };
      };
      templates = {
        "ntfy-secrets" = {
          content = ''
            NTFY_BAUTH_USER=${config.sops.placeholder."ntfy/USER"}
            NTFY_BAUTH_PASS=${config.sops.placeholder."ntfy/PASSWORD"}
          '';
        };
        "ntfy-teslamate" = {
          content = ''
            NTFY_URL=${config.sops.placeholder."ntfy/URL"}/${config.sops.placeholder."ntfy/topics/TESLA"}
          '';
        };
        "ntfy-audiobookshelf" = {
          content = ''
            NTFY_URL=${config.sops.placeholder."ntfy/URL"}/${
              config.sops.placeholder."ntfy/topics/AUDIOBOOKSHELF"
            }
          '';
        };
      };
    };

    environment.etc = {
      "grafana-ntfy/base_conf" = {
        text = ''
          BAUTH_USER=admin
          BAUTH_PASS=admin
          ROCKET_ADDRESS=0.0.0.0
        '';
      };
    };

    environment.etc = {
      "alloy/grafana-ntfy-journald.alloy" = mkIf config.mine.services.alloy.enable {
        text = builtins.readFile ./config.alloy;
      };
    };

    virtualisation.oci-containers.containers."grafana-to-ntfy-teslamate" =
      let
        port = "8880";
        hostname = "ntfy-teslamate";
      in
      {
        image = "kittyandrew/grafana-to-ntfy:latest";
        hostname = "${hostname}";
        ports = [
          "${port}"
        ];
        environment = {
          ROCKET_PORT = "${port}";
        };
        environmentFiles = [
          config.sops.templates."ntfy-secrets".path
          config.sops.templates."${hostname}".path
          config.environment.etc."grafana-ntfy/base_conf".source
        ];
        volumes = [
          "${rocket_toml}:/usr/src/app/Rocket.toml"
        ];
        extraOptions = [
          "--network=traefik"
        ];
      };
    virtualisation.oci-containers.containers."grafana-to-ntfy-audiobookshelf" =
      let
        port = "8881";
        hostname = "ntfy-audiobookshelf";
      in
      {
        image = "kittyandrew/grafana-to-ntfy:latest";
        hostname = "${hostname}";
        ports = [
          "${port}"
        ];
        environment = {
          ROCKET_PORT = "${port}";
        };
        environmentFiles = [
          config.sops.templates."ntfy-secrets".path
          config.sops.templates."${hostname}".path
          config.environment.etc."grafana-ntfy/base_conf".source
        ];
        volumes = [
          "${rocket_toml}:/usr/src/app/Rocket.toml"
        ];
        extraOptions = [
          "--network=traefik"
        ];
      };
  };
}
