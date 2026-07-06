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
          gatus = {
            enable = true;
            endpointsFile = config.nixos-thurs.gatus.privateEndpoints;
            gotifyUrl = "https://gotify.${config.nixos-thurs.publicDomain}";
          };
          gotify = enabled;
          traefik = {
            enable = true;
            enableIpv6 = true;
            awsEnvKeys = false;
            dashboard = true;
            dnsChallengeProvider = "gcp";
            dnsResolvers = "[2606:4700:4700::1111]:53,[2001:4860:4860::8888]:53";
            extraPorts = [
              "${config.mine.homelab.${config.networking.hostName}.tailscaleIp}:443:8443"
              "${config.mine.homelab.${config.networking.hostName}.hostIp}:443:443"
            ];
            extraCmds = [
              "--accesslog=true"
              "--experimental.plugins.fail2ban.modulename=github.com/tomMoulard/fail2ban"
              "--experimental.plugins.fail2ban.version=v0.9.0"
              "--certificatesresolvers.letsencrypt.acme.dnschallenge.disablepropagationcheck=true"
              "--certificatesresolvers.letsencrypt.acme.dnschallenge.delaybeforecheck=15"
            ];
          };
        };

        services = {
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
