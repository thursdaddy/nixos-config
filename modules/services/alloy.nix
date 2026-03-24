_: {
  flake.modules.nixos.services =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.mine.services.${name};
      name = "alloy";
      port = 12346;
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkOption {
          description = "Grafana Alloy";
          type = lib.types.bool;
          default = true;
        };
      };

      config = lib.mkIf cfg.enable {
        networking.firewall.allowedTCPPorts = [ port ];

        services.alloy = {
          enable = true;
          package = pkgs.unstable.grafana-alloy;
          extraFlags = [
            "--server.http.listen-addr=0.0.0.0:${builtins.toString port}"
            "--disable-reporting"
          ];
        };

        systemd.services.alloy = {
          serviceConfig = {
            User = "root";
            Group = "root";
            DynamicUser = lib.mkForce false;
          };
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;

            "alloy/config.alloy" = {
              text = ''
                loki.relabel "journal" {
                  forward_to = []

                  rule {
                    source_labels = ["__journal__systemd_unit"]
                    target_label  = "unit"
                  }
                  rule {
                    source_labels = ["__journal__hostname"]
                    target_label  = "host"
                  }
                }

                loki.write "grafana_loki" {
                  endpoint {
                    url = "https://loki.thurs.pw/loki/api/v1/push"
                  }
                }
              '';
            };
          };
      };
    };
}
