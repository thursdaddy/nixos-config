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

      checkedConfigFile =
        pkgs.runCommand "checked-celler-server.toml"
          {
            configFile = config.services.cellerd.configFile;
          }
          ''
            cat $configFile

            export CELLER_SERVER_TOKEN_HS256_SECRET_BASE64="dGVzdCBzZWNyZXQ="
            export CELLER_SERVER_DATABASE_URL="sqlite://:memory:"
            ${config.services.cellerd.package}/bin/cellerd --mode check-config -f $configFile
            cat <$configFile >$out
          '';

      celleradmShim = pkgs.writeShellScript "celleradm" ''
        if [ -n "$CELLERADM_PWD" ]; then
          cd "$CELLERADM_PWD"
          if [ "$?" != "0" ]; then
            >&2 echo "Warning: Failed to change directory to $CELLERADM_PWD"
          fi
        fi

        exec ${config.services.cellerd.package}/bin/celleradm -f ${checkedConfigFile} "$@"
      '';

      celleradmWrapper = pkgs.writeShellScriptBin "cellerd-celleradm" ''
        exec systemd-run \
          --quiet \
          --pipe \
          --pty \
          --wait \
          --collect \
          --service-type=exec \
          --property=EnvironmentFile=${config.services.cellerd.environmentFile} \
          --property=DynamicUser=yes \
          --property=User=${config.services.cellerd.user} \
          --property=Environment=CELLERADM_PWD=$(pwd) \
          --working-directory / \
          -- \
          ${celleradmShim} "$@"
      '';

      initReplicationScript = pkgs.writeText "init-replication.sh" ''
        #!/bin/bash
        set -e
        psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
            CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '$REPLICATION_PASSWORD';
        EOSQL
        echo "host replication replicator 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"
      '';

      celler-rrsync-shim = pkgs.writeShellScriptBin "celler-rrsync-shim" ''
        case "$SSH_ORIGINAL_COMMAND" in
          "rsync --server "*"/var/lib/cellerd/storage/" | "rsync --server "*"/var/lib/cellerd/storage")
            exec ${pkgs.rsync}/bin/rsync ''${SSH_ORIGINAL_COMMAND#rsync}
            ;;
          *)
            echo "Access denied: Only rsync server mode for celler storage is permitted." >&2
            exit 1
            ;;
        esac
      '';
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
          replication = {
            enable = lib.mkEnableOption "Enable PostgreSQL streaming replication";
            role = lib.mkOption {
              type = lib.types.enum [ "primary" "standby" ];
              description = "PostgreSQL replication role (primary or standby)";
            };
            primaryHost = lib.mkOption {
              type = lib.types.str;
              default = "192.168.10.60";
              description = "Primary PostgreSQL host IP";
            };
          };
          backupSync = {
            enable = lib.mkEnableOption "Enable NAR storage sync on path change";
            targetHost = lib.mkOption {
              type = lib.types.str;
              description = "The target passive host to sync data to.";
            };
            interface = lib.mkOption {
              type = lib.types.str;
              description = "The network interface carrying the Virtual IP.";
            };
            virtualIp = lib.mkOption {
              type = lib.types.str;
              default = "192.168.10.54";
              description = "The Virtual IP to check.";
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.celler = {
            traefik.static = {
              celler = {
                inherit port;
                dns = false; # Prevent blocky from auto-scraping host-specific IPs
              };
            };
          };
        };

        services.cellerd = {
          enable = true;
          mode = cfg.mode;
          environmentFile = config.sops.templates."cellerd_env".path;
          settings = {
            listen = "[::]:5455"; # Use port 5455 to avoid conflicts with Attic
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
          };
        };

        services.cellerd.settings = {
          database.url = lib.mkIf (!cfg.replication.enable) (lib.mkDefault "sqlite:///var/lib/cellerd/server.db?mode=rwc");
        };

        # Postgres DB container for celler
        virtualisation.oci-containers.containers.celler-db = {
          image = "postgres:17.6-alpine";
          pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
          hostname = "celler-db";
          ports = [
            "0.0.0.0:54546:5432" # Use port 54546 to avoid conflicts with attic-db (54545)
          ];
          volumes = [
            "/opt/configs/celler/db:/var/lib/postgresql/data"
          ] ++ lib.optionals (cfg.replication.enable && cfg.replication.role == "primary") [
            "${initReplicationScript}:/docker-entrypoint-initdb.d/init-replication.sh:ro"
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
            "attic/SERVER_TOKEN_BASE64_SECRET" = { };
            "attic/DB_PASS" = { };
          };
          templates = {
            "cellerd_env" = {
              content = ''
                CELLER_SERVER_TOKEN_RS256_SECRET_BASE64="${config.sops.placeholder."attic/SERVER_TOKEN_BASE64_SECRET"}"
                CELLER_SERVER_DATABASE_URL="postgresql://celler:${config.sops.placeholder."attic/DB_PASS"}@127.0.0.1:54546/celler"
              '';
            };
            "celler-db".content = ''
              POSTGRES_PASSWORD=${config.sops.placeholder."attic/DB_PASS"}
              REPLICATION_PASSWORD=${config.sops.placeholder."attic/DB_PASS"}
            '';
          };
        };

        networking.firewall.allowedTCPPorts = [ 5455 54546 ];

        # Standby database initialization hook
        systemd.services.podman-celler-db = lib.mkIf (cfg.replication.enable && cfg.replication.role == "standby") {
          after = [ "sops-nix.service" ];
          serviceConfig.ExecStartPre = pkgs.writeShellScript "celler-db-standby-init" ''
            if [ ! -f /opt/configs/celler/db/pgdata/standby.signal ]; then
              echo "Standby database not initialized. Performing pg_basebackup..."
              mkdir -p /opt/configs/celler/db
              
              PASSWORD=$(${pkgs.gnugrep}/bin/grep REPLICATION_PASSWORD ${config.sops.templates."celler-db".path} | ${pkgs.coreutils}/bin/cut -d= -f2)
              
              rm -rf /opt/configs/celler/db/pgdata
              
              PGPASSWORD=$PASSWORD ${pkgs.podman}/bin/podman run --rm \
                -e PGPASSWORD \
                -v /opt/configs/celler/db:/var/lib/postgresql/data \
                postgres:17.6-alpine \
                pg_basebackup -h ${cfg.replication.primaryHost} -p 54546 -U replicator -D /var/lib/postgresql/data/pgdata -Fp -Xs -R
                
              chown -R root:root /opt/configs/celler/db
            fi
          '';
        };



        users.groups.cellerd = { };
        users.users.cellerd = {
          isSystemUser = true;
          group = "cellerd";
          description = "Celler Daemon User";
        };

        users.users.celler-sync = {
          isSystemUser = true;
          group = "cellerd";
          description = "Celler Active-Standby Sync User";
          createHome = true;
          home = "/var/lib/celler-sync";
          shell = pkgs.bash;
        };

        # Active-to-passive synchronization service for NAR files
        systemd.services.celler-sync = lib.mkIf cfg.backupSync.enable {
          description = "Sync Celler NAR storage to passive node";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            User = "celler-sync";
            Group = "cellerd";
            ExecStart = pkgs.writeShellScript "celler-sync.sh" ''
              # Check if this node is currently the active MASTER (holds the VIP)
              if ! ${pkgs.iproute2}/bin/ip addr show dev ${cfg.backupSync.interface} | grep -q "${cfg.backupSync.virtualIp}"; then
                echo "This node is not the active MASTER. Skipping sync."
                exit 0
              fi

              # Generate dynamic SSH key pair if not exists
              if [ ! -f /var/lib/celler-sync/.ssh/id_ed25519 ]; then
                echo "Generating SSH key pair for celler-sync..."
                mkdir -p /var/lib/celler-sync/.ssh
                chmod 700 /var/lib/celler-sync/.ssh
                ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f /var/lib/celler-sync/.ssh/id_ed25519
                chown -R celler-sync:cellerd /var/lib/celler-sync/.ssh
              fi

              echo "Syncing NAR storage..."
              ${pkgs.rsync}/bin/rsync -avz --no-owner --no-group --omit-dir-times --delete \
                -e "${pkgs.openssh}/bin/ssh -i /var/lib/celler-sync/.ssh/id_ed25519 -o StrictHostKeyChecking=accept-new" \
                /var/lib/cellerd/storage/ celler-sync@${cfg.backupSync.targetHost}:/var/lib/cellerd/storage/
              echo "Sync complete."
            '';
          };
        };

        # Periodically trigger sync to synchronize new NARs
        systemd.timers.celler-sync = lib.mkIf cfg.backupSync.enable {
          description = "Timer to trigger Celler NAR storage synchronization";
          timerConfig = {
            OnBootSec = "15m";
            OnUnitActiveSec = "15m";
            Unit = "celler-sync.service";
          };
          wantedBy = [ "timers.target" ];
        };

        systemd.services.cellerd = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          serviceConfig = {
            ExecStart = "${config.services.cellerd.package}/bin/cellerd -f ${checkedConfigFile} --mode ${config.services.cellerd.mode}";
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
          celleradmWrapper
          celler-rrsync-shim
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
