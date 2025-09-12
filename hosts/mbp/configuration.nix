{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let

  inherit (lib.thurs) enabled;
  inherit (config.mine) user;

in
{
  imports = [
    ../../overlays/unstable
    ../../modules/darwin/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    nixpkgs.hostPlatform = "aarch64-darwin";

    system = {
      stateVersion = 5;
      primaryUser = "${user.name}";
    };

    # https://nixpk.gs/pr-tracker.html?pr=400290
    nixpkgs.overlays = [
      (self: super: {
        nodejs = super.nodejs_22;
        nodejs-slim = super.nodejs-slim_22;
      })
    ];

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        ghToken = enabled;
        shell.package = pkgs.zsh;
      };

      home-manager = {
        ghostty = enabled;
        git = enabled;
        ssh-config = enabled;
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

      apps = {
        aldente = enabled;
        chromium = enabled;
        discord = enabled;
        element = enabled;
        ghostty = enabled;
        keybase = enabled;
        obsidian = enabled;
        ollama = enabled;
        proton = enabled;
        prusa-slicer = enabled;
        steam = enabled;
        syncthing = enabled;
        tailscale = enabled;
        vivaldi = enabled;
      };

      cli-tools = {
        ansible = enabled;
        awscli = enabled;
        charm-freeze = enabled;
        crush = enabled;
        direnv = enabled;
        fastfetch = enabled;
        homebrew = enabled;
        just = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
          ageKeyFile = {
            path = "${user.homeDir}/.config/sops/age/keys.txt";
          };
        };
      };

      services = {
        docker = enabled;
      };

      system = {
        defaults = enabled;
        fonts = enabled;
        nix = {
          index = enabled;
          unfree = enabled;
        };
        security.touchsudo = enabled;
        utils = {
          dev = true;
          sysadmin = true;
        };
        virtualisation.utm = enabled;
      };
    };
  };
}
