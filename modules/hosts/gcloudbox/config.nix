_: {
  configurations.nixos.gcloudbox.module =
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
            hostName = "gcloudbox";
            ipv4Forwarding = enabled;
          };
          sops.ageKeyFile = {
            path = "/var/lib/sops-age/keys.txt";
            ageKeyInGCP = {
              enable = true;
              secretName = "sops-age-key";
            };
          };
        };

        homelab.gcloudbox = {
          tailscaleIp = "100.120.212.123";
          hostIp = "10.128.0.4";
          rootDomainName = config.nixos-thurs.publicDomain;
        };

        containers = {
          settings.backend = "podman";
          gatus = {
            enable = true;
            endpointsFile = config.nixos-thurs.gatus.privateEndpoints;
            gotifyUrl = "https://gotify.thurs.cloud";
          };
          gotify = enabled;
          traefik = {
            enable = true;
            enableIpv6 = false;
            awsEnvKeys = false;
            dashboard = true;
            dnsChallengeProvider = "gcp";
            dnsResolvers = "1.1.1.1:53,8.8.8.8:53";
            extraPorts = [
              "${config.mine.homelab.${config.networking.hostName}.tailscaleIp}:443:8443"
              "${config.mine.homelab.${config.networking.hostName}.hostIp}:443:443"
              "[::]:443:443"
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
              "--accept-dns=true"
            ];
          };
        };
      };

      services.journald.extraConfig = ''
        SystemMaxUse=1G
      '';

      nix.settings.trusted-users = [
        "@wheel"
      ];

      security.googleOsLogin.enable = lib.mkForce false;

      services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
    };
}
