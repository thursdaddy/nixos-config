{ lib }:
{
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

  mkAlloyUserJournal =
    {
      name,
      serviceName ? name,
    }:
    let
      clean_name = builtins.replaceStrings [ "-" ] [ "_" ] name;
    in
    {
      name = "alloy/${clean_name}-user-journal.alloy";
      value = {
        text = ''
          loki.source.journal "${clean_name}" {
            forward_to = [loki.write.grafana_loki.receiver]
            relabel_rules = loki.relabel.journal.rules

            matches = "_SYSTEMD_USER_UNIT=${serviceName}.service"
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
