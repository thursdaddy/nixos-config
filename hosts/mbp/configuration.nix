{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in
{
  imports = [
    ../../overlays/unstable
    ../../modules/darwin/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        ssh-config = enabled;
      };

      apps = {
        chromium = enabled;
        discord = enabled;
        firefox = enabled;
        keybase = enabled;
        kitty = enabled;
        obsidian = enabled;
        protonvpn = enabled;
        syncthing = enabled;
      };

      cli-tools = {
        direnv = enabled;
        git = {
          enable = true;
          ghToken = true;
        };
        homebrew = enabled;
        neofetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/main.yaml");
          ageKeyFile = {
            path = "${user.homeDir}/.config/sops/age/keys.txt";
          };
        };
        tmux = {
          enable = true;
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/projects/nix"
              "${user.homeDir}/projects/cloud"
            ];
          };
        };
      };

      system = {
        security.touchsudo = enabled;
        utils = enabled;
      };
    };
  };
}
