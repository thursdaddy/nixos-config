{ lib, pkgs, ... }:
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

      cli-tools = {
        bottom = enabled;
        direnv = enabled;
        just = enabled;
        fastfetch = enabled;
        nixvim = enabled;
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
          networkd = {
            enable = true;
            hostname = "homebox";
          };
          firewall = enabled;
          resolved = enabled;
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
