{ lib, pkgs, config, ... }:
let
  inherit (config.mine) user;
  inherit (lib.thurs) enabled;
in
{

  imports = [
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    # mine.user.enable does not set initialPassword since it uses SSH Keys by default
    users.users.thurs.initialPassword = "changeme";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        shell.package = pkgs.fish;
      };

      home-manager = {
        git = enabled;
        tmux = {
          enable = true;
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/projects/nix"
              "${user.homeDir}/projects/cloud"
              "${user.homeDir}/projects/homelab"
              "${user.homeDir}/projects/personal"
            ];
          };
        };
        zsh = enabled;
      };

      cli-tools = {
        direnv = enabled;
        git = enabled;
      };

      services = {
        docker = enabled;
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
        utils = enabled;
      };
    };
  };
}
