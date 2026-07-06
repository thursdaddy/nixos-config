_: {
  flake.modules.nixos.services =
    {
      config,
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
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.nginx = {
            traefik.static.nginx = {
              inherit port;
            };
          };
        };

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

        services.logrotate.settings.nginx = {
          su = lib.mkForce "root root";
        };

        environment.etc =
          let
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
            alloyJournal
            alloyAccessLog
          ];
      };
    };
}
