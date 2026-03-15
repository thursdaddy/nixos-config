{ lib }:
{
  enabled = {
    enable = true;
  };

  disabled = {
    enable = false;
  };

  mkTraefikFile =
    {
      name,
      domain ? (
        config.mine.services.traefik.rootDomainName or config.mine.containers.traefik.rootDomainName
      ),
      ip ? "127.0.0.1",
      port,
      config,
    }:
    {
      name = "traefik/providers/${name}.toml";
      value = {
        text = ''
          [http.routers]
            [http.routers.${name}]
              rule = "Host(`${name}.${domain}`)"
              service = "${name}"
              entryPoints = ["websecure"]
              [http.routers.${name}.tls]
                certResolver = "letsencrypt"

          [http.services]
            [http.services.${name}.loadBalancer]
              [[http.services.${name}.loadBalancer.servers]]
                url = "http://${ip}:${toString port}"
        '';
      };
    };

  mkAlloyJournal =
    {
      name,
      serviceName ? name,
    }:
    let
      clean_name = builtins.replaceStrings [ "-" ] [ "_" ] name;
    in
    {
      name = "alloy/${clean_name}-journal.alloy";
      value = {
        text = ''
          loki.source.journal "${clean_name}" {
            forward_to = [loki.write.grafana_loki.receiver]
            relabel_rules = loki.relabel.journal.rules

            matches = "_SYSTEMD_UNIT=${serviceName}.service"
            labels = {
              "app" = "${clean_name}",
              "source" = "journal",
            }
          }
        '';
      };
    };

  mkAlloyFileMatch =
    {
      config,
      name,
      path,
      syncPeriod ? "5s",
    }:
    {
      name = "alloy/${name}-file-match.alloy";
      value = {
        text = ''
          local.file_match "${name}" {
            path_targets = [
              {"__path__" = "${path}"},
            ]
            sync_period = "${syncPeriod}"
          }

          loki.source.file "${name}" {
            targets    = local.file_match.${name}.targets
            forward_to = [loki.relabel.${name}_file.receiver]
          }

          loki.relabel "${name}_file" {
            forward_to = [loki.write.grafana_loki.receiver]

            rule {
              target_label = "app"
              replacement  = "${name}"
            }

            rule {
              target_label = "host"
              replacement  = "${config.networking.hostName}"
            }
          }
        '';
      };
    };
}
