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
      };

      config = lib.mkIf cfg.enable {
        services.traefik = {
          enable = true;
          environmentFiles = [ config.sops.templates."traefik.keys.env".path ];
          staticConfigOptions = {
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
                provider = "route53";
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
          };
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        systemd.tmpfiles.rules = [
          "f ${acmeStorage} 0600 traefik traefik - -"
        ];

        sops = {
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
        };
      };
    };
}
