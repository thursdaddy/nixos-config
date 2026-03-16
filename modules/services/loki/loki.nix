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
        subdomain = lib.mkOption {
          description = "Container url, used by blocky to create DNS entry";
          type = lib.types.str;
          default = name;
        };
      };

      config = lib.mkIf cfg.enable {
        services.loki = {
          enable = true;
          configFile = config_file;
          dataDir = "/mnt/data/loki";
        };

        networking.firewall.allowedTCPPorts = [ 3100 ];

        mine.base.nfs-mounts = {
          mounts = {
            "/mnt/data/loki" = {
              device = "192.168.10.12:/fast/data/loki";
            };
          };
        };

        environment.etc =
          let
            traefik = lib.thurs.mkTraefikFile {
              inherit config;
              inherit name;
              inherit port;
              ip = "192.168.10.68";
            };
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
          in
          builtins.listToAttrs [
            traefik
            alloyJournal
          ];

      };
    };
}
