{ lib, pkgs, inputs, config, ... }:
with lib.thurs;
{

  imports = [
    ../../modules/nixos/import.nix
    ../../modules/nixvim/import.nix
  ];

  config = {
    system.stateVersion = "23.11";

    mine = {
      user = enabled;

      services = {
        openssh = enabled;
      };

      system = {
        networking = {
          enable = true;
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
