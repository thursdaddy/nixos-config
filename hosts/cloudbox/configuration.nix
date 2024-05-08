{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in
{
  imports = [
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    inputs.nixos-thurs.nixosModules.cloudboxContainers
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
      user = enabled;

      tools = {
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/cloudbox.yaml");
          ageKeyFile = {
            path = "/root/age.key";
          };
        };
      };

      services = {
        openssh = enabled;
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
