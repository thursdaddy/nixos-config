{ pkgs, lib, config, inputs, hostname, ... }:
with lib;
with lib.thurs;
{
  imports = [
    inputs.nixos-thurs.nixosModules.netpiContainers
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "23.11";

    environment.systemPackages = with pkgs; [
      neovim
    ];

    mine = {
      user = {
        enable = true;
        home-manager = true;
        ssh-config = enabled;
      };

      tools = {
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/netpi.yaml");
        };
        tmux = enabled;
      };

      services = {
        openssh = enabled;
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--advertise-routes=192.168.20.0/24" ];
        };
      };

      system = {
        networking = {
          enable = true;
          firewall = enabled;
          hostname = "${hostname}";
          forwarding.ipv4 = true;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
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
