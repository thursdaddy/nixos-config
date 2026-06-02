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
          };
        };

        homelab.cloudbox = {
          tailscaleIp = "100.71.122.112";
          hostIp = config.nixos-thurs.publicIp;
          rootDomainName = config.nixos-thurs.publicDomain;
        };

        containers = {
          settings.backend = "podman";
          gatus = {
            enable = true;
            endpointsFile = config.nixos-thurs.gatus.privateEndpoints;
            gotifyUrl = "https://gotify.${config.nixos-thurs.publicDomain}";
          };
          gotify = enabled;
          seerr = enabled;
          traefik = {
            enable = true;
            awsEnvKeys = false;
            dashboard = true;
            extraPorts = [
              "${config.mine.homelab.${config.networking.hostName}.tailscaleIp}:443:8443"
              "10.20.10.184:8082:8082"
              "10.20.10.184:443:443"
            ];
            extraCmds = [
              "--accesslog=true"
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
            ];
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
