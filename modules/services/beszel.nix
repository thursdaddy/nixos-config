_: {
  flake.modules.nixos.services =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.mine.services;
    in
    {
      options.mine.services = {
        beszel-hub = lib.mkOption {
          default = { };
          description = "Beszel Hub settings.";
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "Beszel Hub";
              dataDir = lib.mkOption {
                type = lib.types.path;
                default = "/opt/configs/beszel-hub";
                description = "Path for stored data.";
              };
              listenAddress = lib.mkOption {
                type = lib.types.str;
                default = "0.0.0.0";
                description = "Address for the webserver.";
              };
              port = lib.mkOption {
                type = lib.types.port;
                default = 8890;
                description = "Port for the webserver.";
              };
            };
          };
        };
        beszel-agent = lib.mkOption {
          default = { };
          description = "Beszel Agent settings.";
          type = lib.types.submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable beszel agent";
              };
              port = lib.mkOption {
                type = lib.types.port;
                default = 45876;
                description = "Port for the agent";
              };
            };
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (cfg.beszel-hub.enable || cfg.beszel-agent.enable) {
          environment.systemPackages = with pkgs; [
            unstable.beszel
          ];
        })

        (lib.mkIf cfg.beszel-hub.enable ({
          systemd.services.beszel-hub = {
            description = "Beszel-Hub";
            wantedBy = [ "multi-user.target" ]; # Standard for services
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            environment = {
              APP_URL = "https://monitor.thurs.pw";
            };
            serviceConfig = {
              ExecStart = "${pkgs.unstable.beszel}/bin/beszel-hub serve --http ${cfg.beszel-hub.listenAddress}:${builtins.toString cfg.beszel-hub.port} --dir ${cfg.beszel-hub.dataDir}";
              Type = "simple";
              Restart = "always";
              RestartSec = "5s";
            };
          };

          mine.homelab.${config.networking.hostName} = {
            apps.beszel = {
              traefik.static = {
                monitor.port = cfg.beszel-hub.port;
              };
            };
          };
        }))

        (lib.mkIf cfg.beszel-agent.enable {
          systemd.services.beszel-agent = {
            description = "Beszel-Agent";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            environment = {
              PORT = "${builtins.toString cfg.beszel-agent.port}";
              HUB_URL = "https://monitor.thurs.pw";
            };
            serviceConfig = {
              EnvironmentFile = config.sops.templates."beszel-hub-pub-key".path;
              ExecStart = "${pkgs.unstable.beszel}/bin/beszel-agent";
              Type = "simple";
              Restart = "always";
              RestartSec = "5s";
              X-Restart-Triggers = [
                config.sops.templates."beszel-hub-pub-key".path
              ];
            };
          };

          networking.firewall.allowedTCPPorts = [
            cfg.beszel-hub.port
          ];

          sops = {
            secrets = {
              "beszel/HUB_PUB_KEY" = { };
              "beszel/TOKEN" = { };
            };
            templates."beszel-hub-pub-key".content = ''
              KEY=${config.sops.placeholder."beszel/HUB_PUB_KEY"}
              TOKEN=${config.sops.placeholder."beszel/TOKEN"}
            '';
          };
        })
      ];
    };
}
