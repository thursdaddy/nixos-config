{ lib, pkgs, inputs, config, ... }:
with lib.thurs;
{

  imports = [
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/nixos/import.nix
    ../../overlays/unstable
  ];


  config = {
    system.stateVersion = "24.05";

    ec2.hvm = true;

    mine = {
      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
        useRoutingFeatures = "client";
        extraUpFlags = [ "--accept-routes" "--accept-dns=true" ];
      };

      system = {
        networking = {
          resolved = enabled;
          forwarding.ipv4 = true;
          networkd = {
            enable = true;
            hostname = "null";
          };
        };
        nix = {
          flakes = enabled;
        };
        services = {
          openssh = {
            enable = true;
            root = true;
          };
        };
        utils = enabled;
      };

      cli-tools = {
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
