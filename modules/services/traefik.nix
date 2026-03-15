_: {
  flake.modules.nixos.services =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.traefik;
      acmeStorage = "/var/lib/traefik/acme.json";
      envFileContents = ''
        AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."aws/traefik/AWS_SECRET_ACCESS_KEY"}
        AWS_ACCESS_KEY_ID=${config.sops.placeholder."aws/traefik/AWS_ACCESS_KEY_ID"}
        AWS_HOSTED_ZONE_ID=${config.sops.placeholder."aws/traefik/AWS_HOSTED_ZONE_ID"}
        AWS_REGION="us-west-2";
      '';
    in
    {
      options.mine.services.traefik = {
        enable = lib.mkEnableOption "Enable Traefik system service.";
        rootDomainName = lib.mkOption {
          description = "Root domain name";
          type = lib.types.str;
          default = "thurs.pw";
        };
        dnsChallengeProvider = lib.mkOption {
          description = "Base path for storing container configs";
          type = lib.types.str;
          default = "route53";
        };
      };

      config = lib.mkIf cfg.enable {
        services.traefik = {
          enable = true;
          environmentFiles = [ config.sops.templates."traefik.keys.env".path ];
          staticConfigOptions = {
            global = {
              checkNewVersion = false;
              sendAnonymousUsage = false;
            };

            log.level = "INFO";

            api = {
              dashboard = false;
              insecure = false;
            };

            # Note: Nix handles the directory setup, but you define it here
            providers.file = {
              directory = "/etc/traefik/providers";
              watch = true;
            };

            entryPoints = {
              web.address = ":80";
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

        sops = {
          secrets = {
            "aws/traefik/AWS_ACCESS_KEY_ID" = { };
            "aws/traefik/AWS_SECRET_ACCESS_KEY" = { };
            "aws/traefik/AWS_HOSTED_ZONE_ID" = { };
          };
          templates = {
            "traefik.keys.env".content = envFileContents;
          };
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        users.users.traefik.extraGroups = lib.mkIf (
          config.virtualisation.oci-containers.backend == "docker"
        ) [ "docker" ];

        systemd.tmpfiles.rules = [
          "f ${acmeStorage} 0600 traefik traefik - -"
        ];

        environment.etc."traefik/providers/traefik.toml".text = ''
          [http.routers]
            [http.routers.traefik]
              rule = "Host(`traefik.${config.mine.services.traefik.rootDomainName}`)"
              entryPoints = ["websecure"]
              service = "api@internal"
              [http.routers.traefik.tls]
                certResolver = "letsencrypt"
                [[http.routers.traefik.tls.domains]]
                  main = "${config.mine.services.traefik.rootDomainName}"
                  sans = ["*.${config.mine.services.traefik.rootDomainName}"]

            [http.routers.http-catchall]
              rule = "HostRegexp(`^.+\\.${config.mine.services.traefik.rootDomainName}`)"
              entryPoints = ["web"]
              middlewares = ["redirect-to-https"]
              service = "noop@internal"

          [http.middlewares]
            [http.middlewares.redirect-to-https.redirectScheme]
              scheme = "https"
        '';
      };
    };
}
