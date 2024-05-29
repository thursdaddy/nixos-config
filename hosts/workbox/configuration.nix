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
    system.stateVersion = "23.11";

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
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/main.yaml");
        };
        tmux = enabled;
      };

      services = {
        tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          # extraUpFlags = [ ];
        };
      };

      system = {
        boot = {
          systemd = enabled;
        };
        networking = {
          networkd = {
            enable = true;
            hostname = "workbox";
          };
          firewall = enabled;
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
