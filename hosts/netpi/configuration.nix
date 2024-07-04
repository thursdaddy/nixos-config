{ pkgs, lib, config, inputs, hostname, ... }:
with lib;
with lib.thurs;
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "24.05";

    environment.systemPackages = with pkgs; [
      neovim
    ];

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        ssh-config = enabled;
      };

      cli-tools = {
        bottom = enabled;
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/netpi.yaml");
        };
        tmux = enabled;
      };

      services = {
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--advertise-routes=192.168.20.0/24" ];
        };
        prometheus = {
          enable = true;
          exporters.node = enabled;
        };
      };

      system = {
        networking = {
          networkmanager = {
            enable = true;
            hostname = "${hostname}";
          };
          firewall = enabled;
          forwarding.ipv4 = true;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        security.sudonopass = enabled;
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
