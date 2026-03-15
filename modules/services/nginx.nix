_: {
  flake.modules.nixos.services =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      name = "nginx";
      port = 8080;
      cfg = config.mine.services.${name};
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkEnableOption "Enable NGINX";
        subdomain = lib.mkOption {
          description = "Container url";
          type = lib.types.str;
          default = name;
        };
      };
      config = lib.mkIf cfg.enable {
        networking.firewall.allowedTCPPorts = [ port ];

        services.nginx = {
          enable = true;
          virtualHosts."localhost" = {
            listen = [
              {
                addr = "0.0.0.0";
                port = port;
              }
            ];
            root = "/var/www/my-site";
          };
        };

        environment.etc =
          let
            traefik = lib.thurs.mkTraefikFile {
              inherit config;
              inherit name;
              inherit port;
            };
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
            alloyAccessLog = lib.thurs.mkAlloyFileMatch {
              inherit config;
              inherit name;
              path = "/var/log/nginx/access.log";
            };
          in
          builtins.listToAttrs [
            traefik
            alloyJournal
            alloyAccessLog
          ];
      };
    };
}
