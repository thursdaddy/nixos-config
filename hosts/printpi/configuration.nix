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

    fileSystems."/opt/configs" = {
      device = "192.168.20.12:/fast/configs";
      fsType = "nfs";
      options = [ "auto" "rw" "defaults" "_netdev" ];
    };

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
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml");
        };
        tmux = enabled;
      };

      services = {
        octoprint = enabled;
      };

      system = {
        desktop = {
          kde = enabled;
        };
        networking = {
          networkmanager = {
            enable = true;
            hostname = "printpi";
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
