{ lib, pkgs, inputs, config, ... }:
with lib.thurs;
{

  imports = [
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/nixos/import.nix
  ];

  config = {
    system.stateVersion = "23.11";

    mine = {
      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
        useRoutingFeatures = "client";
        extraUpFlags = [ "--accept-routes" "--accept-dns=true" ];
      };

      services = {
        openssh = {
          enable = true;
          root = true;
        };
      };

      system = {
        ami = true;
        networking = {
          resolved = enabled;
          forwarding.ipv4 = true;
        };
        nix = {
          flakes = enabled;
        };
        utils = enabled;
      };

      tools = {
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
