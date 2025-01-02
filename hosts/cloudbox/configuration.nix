{ lib, pkgs, inputs, ... }:
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
    system.stateVersion = "24.05";

    environment.systemPackages = with pkgs; [
      awscli2
    ];

    services.journald.extraConfig = ''
      SystemMaxUse=1G
    '';

    nix.settings.trusted-users = [ "ssm-user" "@wheel" ];

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
      };

      cli-tools = {
        neofetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml");
        };
        tmux = enabled;
      };

      services = {
        r53-updater = enabled;
        prometheus = {
          enable = true;
          exporters.node = enabled;
        };
        tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--accept-routes" "--accept-dns=true" ];
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
        shell.zsh = enabled;
        utils = enabled;
        virtualisation = {
          docker = {
            enable = true;
            scripts.check-versions = true;
          };
        };
      };
    };
  };
}
