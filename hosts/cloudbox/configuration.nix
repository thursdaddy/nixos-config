{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in
{

  imports = [
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "23.11";

    sops.secrets.tailscale_auth_key = { };

    mine = {
      user = enabled;

      tools = {
        sops = {
          enable = true;
          defaultSopsFile = (inputs.secrets.packages.${pkgs.system}.secrets + "/encrypted/secrets.yaml");
          # ageKeyFile = "/root/keys.txt";
          ageKeyFile = "${user.homeDir}/.config/sops/age/keys.txt";
        };
      };

      services = {
        openssh = enabled;
        r53-updater = enabled;
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets.tailscale_auth_key.path;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--accept-routes" "--accept-dns=true" ];
        };
      };

      system = {
        networking = {
          enable = true;
          firewall = enabled;
          hostname = "cloudbox";
          forwarding.ipv4 = true;
          resolved = enabled;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        security.sudonopass = enabled;
        shell.zsh = enabled;
        utils = enabled;
        virtualisation = {
          docker = enabled;
        };
      };

      tools = {
        home-manager = enabled;
      };

      cli-apps = {
        neofetch = enabled;
        nixvim = enabled;
      };
    };
  };
}
