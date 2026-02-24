{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib.thurs) enabled;
in
{
  imports = [
    inputs.nixos-thurs.nixosModules.configs
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/home/import.nix
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    services.journald.extraConfig = ''
      SystemMaxUse=1G
    '';

    swapDevices = [
      {
        device = "/swap";
        size = 2 * 1024;
      }
    ];
    nix.settings.trusted-users = [
      "ssm-user"
      "@wheel"
    ];

    security.sudo-rs.enable = true;
    environment.systemPackages = with pkgs; [
      neovim
    ];

    mine = {
      user = {
        enable = true;
        shell.package = pkgs.fish;
      };

      cli-tools = {
        awscli = enabled;
        bottom = enabled;
        fastfetch = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
        ssm-session-manager = enabled;
      };

      container = {
        traefik = {
          enable = true;
          domainName = config.nixos-thurs.publicDomain;
          basicAuth = true;
        };
        vaultwarden = enabled;
        gatus = enabled;
        gotify = enabled;
        overseerr = enabled;
      };

      services = {
        alloy = enabled;
        beszel = {
          enable = true;
          isAgent = true;
        };
        docker = {
          enable = true;
          scripts.check-versions = true;
        };
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
        prometheus = {
          enable = true;
          exporters.node = enabled;
        };
        r53-updater = enabled;
        tailscale = {
          enable = true;
          sopsKey = "tailscale/CLOUDBOX_AUTH_KEY";
          authKeyFile = "/tmp/auth";
          useRoutingFeatures = "client";
          extraUpFlags = [
            "--accept-routes"
          ];
        };
      };

      system = {
        networking = {
          firewall = enabled;
          forwarding.ipv4 = true;
          networkd = {
            enable = true;
            hostname = "cloudbox";
          };
          resolved = enabled;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        services = {
          openssh = enabled;
        };
        utils = enabled;
      };
    };
  };
}
