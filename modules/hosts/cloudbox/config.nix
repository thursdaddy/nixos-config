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
              hostIp = "100.71.122.112";
            };
          };
        };

        containers = {
          gatus = {
            enable = true;
            endpointsFile = config.nixos-thurs.gatus.privateEndpoints;
          };
          gotify = enabled;
          seerr = enabled;
          traefik = {
            enable = true;
            rootDomainName = config.nixos-thurs.publicDomain;
            awsEnvKeys = false;
          };
          vaultwarden = enabled;
        };

        services = {
          backups = {
            enable = true;
            nfs-mount = false;
          };
          r53-updater = enabled;
          tailscale = {
            enable = true;
            useRoutingFeatures = "client";
            sopsSecret = "tailscale/CLOUDBOX_AUTH_KEY";
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
