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

  # Shamelessly stolen from home-manager
  toHyprconf =
    {
      attrs,
      indentLevel ? 0,
      importantPrefixes ? [ "$" ],
    }:
    let
      inherit (lib)
        all
        concatMapStringsSep
        concatStrings
        concatStringsSep
        filterAttrs
        foldl
        generators
        hasPrefix
        isAttrs
        isList
        mapAttrsToList
        replicate
        attrNames
        ;

      initialIndent = concatStrings (replicate indentLevel "  ");

      toHyprconf' =
        indent: attrs:
        let
          isImportantField =
            n: _: foldl (acc: prev: if hasPrefix prev n then true else acc) false importantPrefixes;
          importantFields = filterAttrs isImportantField attrs;
          withoutImportantFields = fields: removeAttrs fields (attrNames importantFields);

          allSections = filterAttrs (n: v: isAttrs v || isList v) attrs;
          sections = withoutImportantFields allSections;

          mkSection =
            n: attrs:
            if isList attrs then
              let
                separator = if all isAttrs attrs then "\n" else "";
              in
              (concatMapStringsSep separator (a: mkSection n a) attrs)
            else if isAttrs attrs then
              ''
                ${indent}${n} {
                ${toHyprconf' "  ${indent}" attrs}${indent}}
              ''
            else
              toHyprconf' indent { ${n} = attrs; };

          mkFields = generators.toKeyValue {
            listsAsDuplicateKeys = true;
            inherit indent;
          };

          allFields = filterAttrs (n: v: !(isAttrs v || isList v)) attrs;
          fields = withoutImportantFields allFields;
        in
        mkFields importantFields
        + concatStringsSep "\n" (mapAttrsToList mkSection sections)
        + mkFields fields;
    in
    toHyprconf' initialIndent attrs;
}
