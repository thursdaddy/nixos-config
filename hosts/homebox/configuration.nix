{ lib, pkgs, inputs, ... }:
let
  inherit (lib.thurs) enabled;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        shell.package = pkgs.fish;
      };

      apps = {
        home-assistant = enabled;
      };

      container = {
        configPath = "/opt/configs";
        traefik = {
          enable = true;
          awsEnvKeys = true;
        };
      };

      cli-tools = {
        bottom = enabled;
        direnv = enabled;
        fastfetch = enabled;
        just = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
      };

      services = {
        docker = enabled;
        beszel = {
          enable = true;
          isAgent = true;
        };
      };

      system = {
        boot = {
          grub = enabled;
        };
        networking = {
          networkmanager = {
            enable = true;
            hostname = "homebox";
          };
          firewall = enabled;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        services = {
          openssh = enabled;
        };
        utils = {
          dev = true;
          sysadmin = true;
        };
      };
    };
  };
}
