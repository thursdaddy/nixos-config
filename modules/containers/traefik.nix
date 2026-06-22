_: {
  flake.modules.nixos.containers =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      name = "traefik";
      version = "3.7.1";

      cfg = config.mine.containers.${name};
      configPath = config.mine.containers.settings.configPath;
      acmeStorage = "/var/lib/traefik/acme.json";
      subdomain = "traefik-${config.networking.hostName}";
      regex_rootDomain = builtins.replaceStrings [ "." ] [ "\\." ] "${cfg.rootDomainName}";

      ociBackend =
        if config.mine.containers.settings.backend == "podman" then
          "podman"
        else if config.mine.containers.settings.backend == "docker" then
          "docker"
        else
          "";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "Enable Traefik";
        subdomain = lib.mkOption {
          description = "Serivce subdomain";
          type = lib.types.str;
          default = subdomain;
        };
        dashboard = lib.mkOption {
          description = "Enable Traefik Dashboard";
          type = lib.types.bool;
          default = false;
        };
        rootDomainName = lib.mkOption {
          description = "Root domain name";
          type = lib.types.str;
          default = config.mine.homelab.${config.networking.hostName}.rootDomainName;
        };
        dnsChallengeProvider = lib.mkOption {
          description = "Base path for storing container configs";
          type = lib.types.str;
          default = "route53";
        };
        awsEnvKeys = lib.mkOption {
          description = "Traefik requires keys to update route53 records.";
          type = lib.types.bool;
          default = true;
        };
        extraCmds = lib.mkOption {
          description = "List of cmd arguments to append";
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        extraLabels = lib.mkOption {
          description = "List of labels to append";
          type = lib.types.attrsOf lib.types.str;
          default = { };
        };
        extraPorts = lib.mkOption {
          description = "List of cmd arguments to append";
          type = lib.types.listOf lib.types.str;
          default = [
            "${config.mine.homelab.${config.networking.hostName}.tailscaleIp}:443:8443"
            "${config.mine.homelab.${config.networking.hostName}.hostIp}:8082:8082"
            "${config.mine.homelab.${config.networking.hostName}.hostIp}:443:443"
          ];
        };
      };

      config = lib.mkIf cfg.enable {
        mine.homelab.${config.networking.hostName} = {
          apps.traefik = {
            traefik.container = lib.mkIf cfg.dashboard {
              subDomain = subdomain;
              tailscale = true;
            };
          };
        };

        virtualisation.oci-containers.containers = {
          "${name}" = {
            image = "traefik:${version}";
            pull = if config.virtualisation.oci-containers.backend == "podman" then "newer" else "missing";
            dependsOn = lib.mkIf (ociBackend == "podman") [ "docker-socket-proxy" ];
            networks = lib.mkIf (ociBackend == "podman") [
              "docker-proxy"
            ];
            ports = cfg.extraPorts ++ [
              "0.0.0.0:80:80"
            ];
            environmentFiles = lib.mkIf cfg.awsEnvKeys [
              config.sops.templates."traefik.keys.env".path
            ];
            environment = {
              AWS_REGION = "us-west-2";
            };
            volumes = [
              "${configPath}/${name}:/etc/traefik/"
              "/var/lib/traefik:/var/lib/traefik/"
            ];
            cmd =
              cfg.extraCmds
              ++ [
                "--log.level=info"
                "--providers.docker=true"
                "--providers.docker.exposedbydefault=false"
                "--providers.docker.endpoint=tcp://docker-socket-proxy:2375"
                "--certificatesresolvers.letsencrypt.acme.dnschallenge=true"
                "--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=${cfg.dnsChallengeProvider}"
                "--certificatesresolvers.letsencrypt.acme.storage=${acmeStorage}"
                "--metrics.prometheus=true"
                "--metrics.prometheus.buckets=0.1,0.3,1.2,5.0"
                "--metrics.prometheus.addEntryPointsLabels=true"
                "--metrics.prometheus.addRoutersLabels=true"
                "--metrics.prometheus.addServicesLabels=true"
                "--metrics.prometheus.entrypoint=metrics"
                "--entrypoints.metrics.address=:8082"
                "--entrypoints.websecure.address=:443"
                "--entrypoints.web.address=:80"
                "--entrypoints.tailscale.address=:8443"
              ]
              ++ lib.optionals (cfg.dashboard) [
                "--api=true"
              ];
            labels =
              cfg.extraLabels
              // {
                "traefik.http.routers.http-catchall.rule" = "HostRegexp(`^.+\\.${regex_rootDomain}`)";
                "traefik.http.routers.http-catchall.entrypoints" = "web";
                "traefik.http.routers.http-catchall.middlewares" = "redirect-to-https@docker";
                "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme" = "https";
              }
              // lib.optionalAttrs (cfg.dashboard) {
                "traefik.enable" = "true";
                "traefik.http.routers.traefik.tls" = "true";
                "traefik.http.routers.traefik.tls.certresolver" = "letsencrypt";
                "traefik.http.routers.traefik.rule" = "Host(`${subdomain}.${
                  config.mine.homelab.${config.networking.hostName}.rootDomainName
                }`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`) || Path(`/`))";
                "traefik.http.routers.traefik.entrypoints" = "tailscale";
                "traefik.http.routers.traefik.service" = "api@internal";
              };
          };

          docker-socket-proxy = lib.mkIf (ociBackend == "podman") {
            image = "tecnativa/docker-socket-proxy:latest";
            hostname = "docker-socket-proxy";
            networks = [ "docker-proxy" ];
            volumes = [
              "/run/podman/podman.sock:/var/run/docker.sock:ro"
            ];
            environment = {
              CONTAINERS = "1";
              SERVICES = "1";
              NETWORKS = "1";
              TASKS = "1";
              POST = "0";
              PUT = "0";
              DELETE = "0";
            };
            labels = {
              "enable.versions.check" = "false";
            };
          };
        };

        systemd.services = {
          create-traefik-proxy-network = {
            description = "Create Traefik proxy network after docker is running";
            after = lib.mkIf (ociBackend == "docker") [ "docker.service" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              ExecStart = [
                "-${lib.getExe pkgs.${ociBackend}} network create docker-proxy"
              ];
            };
          };
          "${ociBackend}-docker-socket-proxy" = {
            requires = [ "create-traefik-proxy-network.service" ];
            after = [ "create-traefik-proxy-network.service" ];
          };
          "${ociBackend}-traefik" = {
            requires = [ "create-traefik-proxy-network.service" ];
            after = [ "create-traefik-proxy-network.service" ];
          };
        };

        networking.firewall.allowedTCPPorts = [ 8082 ]; # prometheus exporter

        sops = {
          secrets = {
            "aws/traefik/AWS_ACCESS_KEY_ID" = lib.mkIf cfg.awsEnvKeys { };
            "aws/traefik/AWS_SECRET_ACCESS_KEY" = lib.mkIf cfg.awsEnvKeys { };
          };
          templates = {
            "traefik.keys.env".content = (lib.mkIf cfg.awsEnvKeys) ''
              AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."aws/traefik/AWS_SECRET_ACCESS_KEY"}
              AWS_ACCESS_KEY_ID=${config.sops.placeholder."aws/traefik/AWS_ACCESS_KEY_ID"}
            '';
          };
        };

        systemd.tmpfiles.rules = [
          "f ${acmeStorage} 0600 traefik traefik - -"
        ];

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "${ociBackend}-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
          };
      };
    };
}
