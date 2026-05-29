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
      regex_rootDomain = builtins.replaceStrings [ "." ] [ "\\." ] "${cfg.rootDomainName}";
      acmeStorage = "/var/lib/traefik/acme.json";
    in
    {
      options.mine.containers.${name} = {
        enable = lib.mkEnableOption "Enable Traefik";
        version = lib.mkOption {
          description = "Container version";
          type = lib.types.str;
          default = version;
        };
        subdomain = lib.mkOption {
          description = "Serivce subdomain";
          type = lib.types.str;
          default = "${name}-${config.networking.hostName}";
        };
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
        ports = lib.mkOption {
          description = "List of cmd arguments to append";
          type = lib.types.listOf lib.types.str;
          default = [
            "0.0.0.0:443:443"
          ];
        };
        basicAuth = lib.mkEnableOption "Enable basic auth file";
      };

      config = lib.mkIf cfg.enable {
        virtualisation.oci-containers.containers."${name}" = {
          image = "traefik:${cfg.version}";
          pull = "always";
          networks = [ "${name}" ];
          ports = cfg.ports ++ [
            "0.0.0.0:80:80"
          ];
          environmentFiles = lib.mkIf cfg.awsEnvKeys [
            config.sops.templates."traefik.keys.env".path
          ];
          environment = {
            AWS_REGION = "us-west-2";
          };
          volumes = [
            "${config.mine.containers.settings.configPath}/${name}:/etc/traefik/"
            "/var/lib/traefik:/var/lib/traefik/"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
            # for static provider files
            "/etc/static/traefik/providers/:/static"
            "/nix/store:/nix/store:ro"
          ]
          ++ lib.optionals cfg.basicAuth [
            "${config.sops.templates."userfile.env".path}:/etc/traefik/userfile"
          ];
          cmd = cfg.extraCmds ++ [
            "--log.level=info"
            "--providers.docker=true"
            "--providers.docker.exposedbydefault=false"
            "--providers.file.directory=/static"
            "--providers.file.watch=true"
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
          ];
          labels = cfg.extraLabels // {
            "traefik.http.routers.http-catchall.rule" = "HostRegexp(`^.+\\.${regex_rootDomain}`)";
            "traefik.http.routers.http-catchall.entrypoints" = "web";
            "traefik.http.routers.http-catchall.middlewares" = "redirect-to-https@docker";
            "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme" = "https";
          };
        };

        systemd.services.create-traefik-network = {
          description = "Create Traefik network after docker is running";
          after = [ "docker.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = [
              "-${lib.getExe pkgs.docker} network create ${name}"
            ];
          };
        };

        sops = {
          secrets = {
            "aws/traefik/AWS_ACCESS_KEY_ID" = lib.mkIf cfg.awsEnvKeys { };
            "aws/traefik/AWS_SECRET_ACCESS_KEY" = lib.mkIf cfg.awsEnvKeys { };
            "traefik/BASIC_AUTH_PASSWORD" = lib.mkIf cfg.basicAuth { };
          };
          templates = {
            "traefik.keys.env".content = (lib.mkIf cfg.awsEnvKeys) ''
              AWS_SECRET_ACCESS_KEY=${config.sops.placeholder."aws/traefik/AWS_SECRET_ACCESS_KEY"}
              AWS_ACCESS_KEY_ID=${config.sops.placeholder."aws/traefik/AWS_ACCESS_KEY_ID"}
            '';
            "userfile.env" = lib.mkIf cfg.basicAuth {
              content = ''
                ${config.mine.base.user.name}:${config.sops.placeholder."traefik/BASIC_AUTH_PASSWORD"}
              '';
            };
          };
        };

        networking.firewall.allowedTCPPorts = [ 8082 ]; # prometheus exporter

        systemd.tmpfiles.rules = [
          "f ${acmeStorage} 0600 traefik traefik - -"
        ];

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
              serviceName = "docker-${name}";
            };
          in
          {
            "${alloyJournal.name}" = alloyJournal.value;
            "traefik/providers/placeholder".text = "";
          };
      };
    };
}
