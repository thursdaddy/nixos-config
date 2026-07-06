_: {
  flake.modules.nixos.services =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.mine.services.traefik;
      acmeStorage = "/var/lib/traefik/acme.json";

      # Convert extraCmds into attributes for staticConfigOptions
      parseCmds = cmds:
        let
          # Helper to split string at the first '='
          splitEq = str:
            let
              parts = lib.splitString "=" str;
              key = lib.head parts;
              val = lib.concatStringsSep "=" (lib.tail parts);
            in
            { inherit key val; };

          cmdList = map (cmd:
            let
              stripped = lib.removePrefix "--" cmd;
              kv = splitEq stripped;
              # Split path by dot
              pathRaw = lib.splitString "." kv.key;
              # Map lowercase to camelCase where necessary
              path = map (k: if k == "modulename" then "moduleName" else k) pathRaw;
              # Coerce values (e.g. booleans or numbers)
              lastPath = lib.last path;
              coercedVal =
                if kv.val == "true" then true
                else if kv.val == "false" then false
                else if (builtins.match "[0-9]+" kv.val != null && builtins.elem lastPath [ "port" "maxretry" "priority" "weight" ]) then builtins.fromJSON kv.val
                else kv.val;
            in
            lib.setAttrByPath path coercedVal
          ) (builtins.filter (cmd: lib.hasPrefix "--" cmd) cmds);
        in
        lib.foldl' lib.recursiveUpdate { } cmdList;

    in
    {
      options.mine.services.traefik = {
        enable = lib.mkEnableOption "Enable Traefik via native systemd service";
        subdomain = lib.mkOption {
          description = "Service subdomain";
          type = lib.types.str;
          default = "traefik-${config.networking.hostName}";
        };
        dashboard = lib.mkOption {
          description = "Enable dashboard";
          type = lib.types.bool;
          default = true;
        };
        dnsChallengeProvider = lib.mkOption {
          description = "Provider for ACME DNS challenge";
          type = lib.types.str;
          default = "route53";
        };
        awsEnvKeys = lib.mkOption {
          description = "Traefik requires keys to update Route53 records.";
          type = lib.types.bool;
          default = true;
        };
        extraCmds = lib.mkOption {
          description = "Extra command line arguments to pass to Traefik";
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
      };

      config = lib.mkIf cfg.enable {
        services.traefik = {
          enable = true;
          environmentFiles = [ config.sops.templates."traefik.keys.env".path ];
          staticConfigOptions = lib.recursiveUpdate {
            log.level = "INFO";
            global = {
              checkNewVersion = false;
              sendAnonymousUsage = false;
            };

            api = {
              dashboard = false;
              insecure = false;
            };

            providers.file = {
              directory = "/etc/traefik/static";
              watch = true;
            };

            entryPoints = {
              web = {
                address = ":80";
                http.redirections.entryPoint = {
                  to = "websecure";
                  scheme = "https";
                };
              };
              websecure = {
                address = ":443";
                transport.respondingTimeouts = {
                  readTimeout = "600s";
                  idleTimeout = "600s";
                };
              };
              metrics.address = ":8082";
            };

            certificatesResolvers.letsencrypt.acme = {
              dnsChallenge = {
                # Traefik internally requires "gcloud", so we map your "gcp" config back to it
                provider = if cfg.dnsChallengeProvider == "gcp" then "gcloud" else cfg.dnsChallengeProvider;
                resolvers = [ "1.1.1.1:53" "8.8.8.8:53" ];
              };
              storage = acmeStorage;
            };

            metrics.prometheus = {
              buckets = [
                0.1
                0.3
                1.2
                5.0
              ];
              addEntryPointsLabels = true;
              addRoutersLabels = true;
              addServicesLabels = true;
              entryPoint = "metrics";
            };
          } (parseCmds cfg.extraCmds);
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        environment.etc."traefik/static/middlewares.yaml".text = ''
          http:
            middlewares:
              local-only:
                ipAllowList:
                  sourceRange:
                    - "127.0.0.1/32"
                    - "192.168.10.0/24"
                    - "100.64.0.0/10"
        '';

        systemd.tmpfiles.rules = [
          "f ${acmeStorage} 0600 traefik traefik - -"
        ];

        sops = lib.mkMerge [
          (lib.mkIf (cfg.dnsChallengeProvider == "route53") {
            secrets = {
              "aws/traefik/AWS_ACCESS_KEY_ID" = { };
              "aws/traefik/AWS_SECRET_ACCESS_KEY" = { };
              "aws/traefik/AWS_HOSTED_ZONE_ID" = { };
            };
            templates = {
              "traefik.keys.env".content = ''
                AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."aws/traefik/AWS_SECRET_ACCESS_KEY"}
                AWS_ACCESS_KEY_ID=${config.sops.placeholder."aws/traefik/AWS_ACCESS_KEY_ID"}
                AWS_HOSTED_ZONE_ID=${config.sops.placeholder."aws/traefik/AWS_HOSTED_ZONE_ID"}
                AWS_REGION=us-west-2
              '';
            };
          })
          (lib.mkIf (cfg.dnsChallengeProvider == "gcp") {
            secrets = {
              "gcp/traefik/PROJECT_ID" = { };
              "gcp/traefik/CREDENTIALS.JSON" = { };
            };
            templates = {
              "traefik.keys.env".content = ''
                GCE_PROJECT=${config.sops.placeholder."gcp/traefik/PROJECT_ID"}
                GCE_SERVICE_ACCOUNT_FILE=${config.sops.secrets."gcp/traefik/CREDENTIALS.JSON".path}
              '';
            };
          })
        ];
      };
    };
}
