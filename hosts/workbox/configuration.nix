{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
{
  imports = [
    ./hardware-configuration.nix
    ./stage1-boot.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "24.05";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
      };

      cli-tools = {
        bottom = enabled;
        git = {
          enable = true;
          ghToken = true;
        };
        neofetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/main.yaml");
        };
        tmux = enabled;
      };

      services = {
        tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
        };
      };

      system = {
        boot = {
          binfmt = enabled;
          systemd = enabled;
        };
        networking = {
          networkd = {
            enable = true;
            hostname = "workbox";
          };
          firewall = disabled;
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
          docker = {
            enable = true;
            scripts.check-versions = true;
          };
        };
      };
    };
  };
}
