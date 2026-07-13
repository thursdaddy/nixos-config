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
          sops.ageKeyFile = {
            path = "/var/lib/sops-age/keys.txt";
            ageKeyInSSM = {
              enable = true;
              paramName = "/sops/age.key";
              region = "us-west-2";
            };
          };
        };

        homelab.cloudbox = {
          tailscaleIp = "100.111.82.27";
          hostIp = "10.20.10.191";
          rootDomainName = config.nixos-thurs.publicDomain;
        };

        containers = {
          settings.backend = "podman";
        };

        services = {
          tailscale = {
            enable = true;
            useRoutingFeatures = "client";
            sopsSecret = "tailscale/CLOUDBOX_AUTH_KEY";
            extraUpFlags = [
              "--accept-routes"
              "--accept-dns=false"
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
