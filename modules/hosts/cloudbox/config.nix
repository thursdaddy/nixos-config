_: {
  configurations.nixos.cloudbox.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.thurs) disabled enabled;
    in
    {
      boot.loader.systemd-boot.configurationLimit = 5;
      mine = {
        base = {
          nix.substituters = disabled;
          networking = {
            hostName = "cloudbox";
            ipv4Forwarding = enabled;
            meta = {
              hostIp = "100.114.10.49";
            };
          };
        };

        containers = {
          gatus = enabled;
          gotify = enabled;
          overseerr = enabled;
          traefik = {
            enable = true;
            rootDomainName = config.nixos-thurs.publicDomain;
            awsEnvKeys = false;
            basicAuth = true;
          };
          vaultwarden = enabled;
        };

        services = {
          gitlab-runner = {
            enable = true;
            runners = {
              backup = {
                tags = [
                  "${config.networking.hostName}"
                  "backup"
                ];
                dockerVolumes = [
                  "/backups:/backups"
                  "/opt/configs:/opt/configs:ro"
                  "/var/run/docker.sock:/var/run/docker.sock"
                ];
              };
            };
          };
          r53-updater = enabled;
          tailscale = {
            enable = true;
            useRoutingFeatures = "client";
            extraUpFlags = [
              "--accept-routes"
            ];
          };
        };
      };

      services.journald.extraConfig = ''
        SystemMaxUse=1G
      '';

      nix.settings.trusted-users = [
        "ssm-user"
        "@wheel"
      ];

      environment.systemPackages = [
        pkgs.ssm-session-manager-plugin
        pkgs.awscli2
      ];
    };
}
