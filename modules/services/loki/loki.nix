_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      name = "loki";
      port = 3100;

      cfg = config.mine.services.${name};

      config_file = pkgs.writeTextFile {
        name = "loki-config.yaml";
        text = builtins.readFile ./loki-config.yaml;
      };
    in
    {
      options.mine.services.loki = {
        enable = lib.mkEnableOption "Grafana Loki";
      };

      config = lib.mkIf cfg.enable {
        services.loki = {
          enable = true;
          configFile = config_file;
          dataDir = "/mnt/data/loki";
        };

        networking.firewall.allowedTCPPorts = [ port ];

        mine = {
          base.nfs-mounts = {
            mounts = {
              "/mnt/data/loki" = {
                device = "192.168.10.12:/fast/data/loki";
              };
            };
          };
          homelab.${config.networking.hostName} = {
            apps.loki = {
              traefik.static.loki = {
                inherit port;
              };
            };
          };
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
