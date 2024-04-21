{ lib, pkgs, inputs, config, ... }:
with lib.thurs;
{

  imports = [
    ../../modules/nixos/import.nix
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
  ];

  config = {
    system.stateVersion = "23.11";

    mine = {
      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        useRoutingFeatures = "client";
        extraUpFlags = [ "--accept-routes" "--accept-dns=true" ];
      };

      services = {
        ssm-agent = enabled;
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
        ssm-session-manager = enabled;
        sops = {
          enable = true;
          requiresNetwork = true;
          defaultSopsFile = (inputs.secrets.packages.${pkgs.system}.secrets + "/encrypted/tailscale_auth.yaml");
        };
      };
    };

    environment.systemPackages = with pkgs; [
      neovim
      git
      awscli2
    ];

  };
}
