{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in
{

  imports = [
    ../../modules/darwin/import.nix
    ../../modules/home/import.nix
  ];

  config = {

    mine = {
      user = {
        enable = true;
        home-manager = true;
      };

      system = {
        security.touchsudo = enabled;
        utils = enabled;
      };

      tools = {
        direnv = enabled;
        git = enabled;
        sops = {
          enable = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/main.yaml");
          ageKeyFile = {
            path = "${user.homeDir}/.confg/sops/age/keys.txt";
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

      cli-apps = {
        homebrew = enabled;
        neofetch = enabled;
        nixvim = enabled;
      };
    };
  };
}
