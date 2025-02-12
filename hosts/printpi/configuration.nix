{ pkgs, lib, inputs, ... }:
with lib;
with lib.thurs;
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    services.rpcbind.enable = true;

    fileSystems."/opt/configs" = {
      device = "192.168.20.12:/fast/configs";
      fsType = "nfs";
      options = [ "auto" "rw" "defaults" "_netdev" "x-systemd.automount" ];
    };

    environment.systemPackages = with pkgs; [
      neovim
    ];

    mine = {
      user = {
        enable = true;
        shell.package = pkgs.fish;
      };

      cli-tools = {
        bottom = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
      };

      services = {
        beszel = {
          enable = true;
          isAgent = true;
        };
        octoprint = enabled;
      };

      system = {
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
