{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  inherit (config.mine) user;

in
{
  imports = [
    ../../overlays/unstable
    ../../modules/darwin/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = 5;
    nixpkgs.hostPlatform = "aarch64-darwin";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        ssh-config = enabled;
        ghToken = enabled;
      };

      apps = {
        chromium = enabled;
        discord = enabled;
        firefox = enabled;
        ghostty = enabled;
        keybase = enabled;
        obsidian = enabled;
        proton = enabled;
        prusa-slicer = enabled;
        syncthing = enabled;
        vivaldi = enabled;
      };

      cli-tools = {
        direnv = enabled;
        git = enabled;
        homebrew = enabled;
        just = enabled;
        neofetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
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
              "${user.homeDir}/projects/homelab"
              "${user.homeDir}/projects/personal"
            ];
          };
        };
      };

      system = {
        fonts = enabled;
        security.touchsudo = enabled;
        utils = enabled;
      };
    };
  };
}
