{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
    ./boot.nix
    ./filesystem.nix
    ./initrd-tailscale.nix
  ];

  config = {
    system.stateVersion = "23.11";

    networking.hostId = "5cdce191";

    environment.systemPackages = [
      pkgs.cryptsetup
      pkgs.sbctl
      pkgs.tpm2-tss
    ];

    systemd.network.enable = true;
    systemd.network.networks."10-lan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "yes";
    };

    networking = {
      useDHCP = false;
      useNetworkd = true;
      hostName = "workbox";
    };

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
          # enable = true;
          hostname = "workbox";
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
