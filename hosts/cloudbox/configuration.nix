{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
{
  imports = [
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "23.11";

    environment.systemPackages = with pkgs; [
      awscli2
    ];

    mine = {
      user = {
        enable = true;
        home-manager = true;
      };

      cli-tools = {
        neofetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/cloudbox.yaml");
        };
        tmux = enabled;
      };

      services = {
        r53-updater = enabled;
        tailscale = {
          enable = true;
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
        services = {
          openssh = enabled;
        };
        security.sudonopass = enabled;
        shell.zsh = enabled;
        utils = enabled;
        virtualisation = {
          docker = enabled;
        };
      };
    };
  };
}
