{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.thurs) enabled;
in
{

  imports = [
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
    ../../overlays/unstable
  ];

  config = {
    system.stateVersion = "25.11";

    ec2.hvm = true;
    virtualisation.diskSize = 5 * 1024;

    nix.settings.trusted-users = [
      "ssm-user"
      "@wheel"
    ];

    sops.secrets."tailscale/CLOUDBOX_AUTH_KEY" = {
      sopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
    };

    mine = {
      user = {
        enable = true;
        shell.package = pkgs.fish;
      };

      services = {
        docker = {
          enable = true;
          scripts.check-versions = true;
        };
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/CLOUDBOX_AUTH_KEY".path;
          useRoutingFeatures = "client";
        };
      };

      system = {
        networking = {
          resolved = enabled;
          networkd = {
            enable = true;
            hostname = "nixos";
          };
        };
        nix = {
          flakes = enabled;
        };
        security.sudonopass = enabled;
        services = {
          openssh = enabled;
        };
        utils = enabled;
      };

      cli-tools = {
        ssm-session-manager = enabled;
        sops = {
          enable = true;
          ageKeyFile = {
            path = "/root/age.key";
            ageKeyInSSM = {
              enable = true;
              paramName = "/sops/age.key";
              region = "us-west-2";
            };
          };
        };
      };
    };
  };
}
