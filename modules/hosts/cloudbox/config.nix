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
              tailscaleIp = "100.71.122.112";
              hostIp = config.nixos-thurs.publicIp;
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
            awsEnvKeys = false;
            rootDomainName = config.nixos-thurs.publicDomain;
            ports = [
              "10.20.10.184:8082:8082"
              "10.20.10.184:443:443"
              "${config.mine.base.networking.meta.tailscaleIp}:443:8443"
            ];
            extraCmds = [
              "--accesslog=true"
              "--entrypoints.tailscale.address=:8443"
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
