{ inputs, ... }: {
  flake.modules.nixos.celler =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      name = "celler";
      port = 5455; # Changed from 5454 to 5455 to avoid port conflicts with Attic
      cfg = config.mine.services.celler;
    in
    {
      options = {
        # Custom Celler module options to avoid importing the official cellerd.nix and triggering disabledModules
        services.cellerd = {
          enable = lib.mkEnableOption "the cellerd, the Nix Binary Cache server";
          package = lib.mkOption {
            type = lib.types.package;
            default = inputs.celler.packages.${pkgs.stdenv.hostPlatform.system}.default;
            description = "Celler package to use";
          };
          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to EnvironmentFile containing secret token";
          };
          user = lib.mkOption {
            type = lib.types.str;
            default = "cellerd";
          };
          group = lib.mkOption {
            type = lib.types.str;
            default = "cellerd";
          };
          settings = lib.mkOption {
            type = (pkgs.formats.toml { }).type;
            default = { };
          };
          configFile = lib.mkOption {
            type = lib.types.path;
            default = (pkgs.formats.toml { }).generate "server.toml" config.services.cellerd.settings;
          };
          mode = lib.mkOption {
            type = lib.types.enum [ "monolithic" "api-server" "garbage-collector" ];
            default = "monolithic";
          };
        };

        mine.services.celler = {
          enable = lib.mkEnableOption "Enable Celler binary cache service";
          mode = lib.mkOption {
            type = lib.types.enum [ "monolithic" "api-server" "garbage-collector" ];
            default = "monolithic";
            description = "Celler execution mode";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.celler = {
            traefik.static = {
              celler = {
                inherit port;
                labels = {
                  "traefik.http.services.celler.loadbalancer.serverstransport" = "cellerTransport";
                  "traefik.http.serversTransports.cellerTransport.forwardingTimeouts.responseHeaderTimeout" = "3600s";
                  "traefik.http.serversTransports.cellerTransport.forwardingTimeouts.idleConnTimeout" = "3600s";
                };
              };
            };
          };
        };

        services.cellerd = {
          enable = true;
          mode = cfg.mode;
          configFile = config.sops.templates."cellerd-server.toml".path;
          environmentFile = null;
          settings = {
            listen = "[::]:5455"; # Use port 5455 to avoid conflicts with Attic
            jwt = {
              rs256-public-key-file = "/var/lib/cellerd/rs256-public-key.pem";
            };
            chunking = {
              avg-size = 65536;
              max-size = 262144;
              min-size = 16384;
              nar-size-threshold = 65536;
            };
            storage = {
              type = "local";
              path = "/var/lib/cellerd/storage";
            };
            database.url = "postgresql://celler:${config.sops.placeholder."attic/DB_PASS"}@127.0.0.1:54546/celler";
          };
        };

        # Postgres DB container for celler
        virtualisation.oci-containers.containers.celler-db = {
          image = "postgres:17.6-alpine";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          hostname = "celler-db";
          ports = [
            "127.0.0.1:54546:5432" # Use port 54546 to avoid conflicts with attic-db (54545)
          ];
          volumes = [
            "/opt/configs/celler/db:/var/lib/postgresql/data"
          ];
          environmentFiles = [
            config.sops.templates."celler-db".path
          ];
          environment = {
            POSTGRES_USER = "celler";
            POSTGRES_DB = "celler";
            PGDATA = "/var/lib/postgresql/data/pgdata";
          };
          labels = {
            "enable.versions.check" = "false";
          };
        };

        sops = {
          secrets = {
            "attic/SERVER_TOKEN_BASE64_SECRET" = {
              owner = config.services.cellerd.user;
            };
            "attic/DB_PASS" = { };
          };
          templates = {
            "cellerd-server.toml" = {
              owner = config.services.cellerd.user;
              group = config.services.cellerd.group;
              content = builtins.readFile (
                (pkgs.formats.toml { }).generate "server.toml" config.services.cellerd.settings
              );
            };
            "celler-db".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."attic/DB_PASS"}
            '';
          };
        };

        networking.firewall.allowedTCPPorts = [ 5455 ];

        users.groups.cellerd = { };
        users.users.cellerd = {
          isSystemUser = true;
          group = "cellerd";
          description = "Celler Daemon User";
        };

        systemd.services.cellerd = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            ExecStartPre = pkgs.writeShellScript "cellerd-extract-pubkey" ''
              ${pkgs.coreutils}/bin/base64 -d ${config.sops.secrets."attic/SERVER_TOKEN_BASE64_SECRET".path} | ${pkgs.openssl}/bin/openssl rsa -pubout -out /var/lib/cellerd/rs256-public-key.pem
            '';
            ExecStart = "${config.services.cellerd.package}/bin/cellerd -f ${config.services.cellerd.configFile} --mode ${config.services.cellerd.mode}";
            EnvironmentFile = config.services.cellerd.environmentFile;
            StateDirectory = "cellerd"; # for usage with local storage and sqlite
            StateDirectoryMode = "0770";
            DynamicUser = false;
            User = config.services.cellerd.user;
            Group = config.services.cellerd.group;
            Restart = "on-failure";
            RestartSec = 10;

            CapabilityBoundingSet = [ "" ];
            DeviceAllow = "";
            DevicePolicy = "closed";
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            NoNewPrivileges = true;
            PrivateDevices = true;
            PrivateTmp = true;
            PrivateUsers = true;
            ProcSubset = "pid";
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHome = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            ProtectSystem = "strict";
            ReadWritePaths =
              let
                path = config.services.cellerd.settings.storage.path;
                isDefaultStateDirectory = path == "/var/lib/cellerd" || lib.hasPrefix "/var/lib/cellerd/" path;
              in
                lib.optionals (config.services.cellerd.settings.storage.type or "" == "local" && !isDefaultStateDirectory) [ path ];
            RemoveIPC = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@resources"
              "~@privileged"
            ];
            UMask = "0007";
          };
        };

        environment.systemPackages = [
          config.services.cellerd.package
        ];

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "cellerd";
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
