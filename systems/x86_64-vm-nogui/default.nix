{ lib, pkgs, ... }:
with lib.thurs;
{

  imports = [
    ../../modules/nixos/import.nix
    ../../modules/nixvim/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    users.users.thurs.initialPassword = "changeme";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
      };

      system = {
        networking = {
          networkd = {
            enable = true;
            hostname = "nixos";
          };
          forwarding.ipv4 = true;
          resolved = enabled;
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
