{ lib, config, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in {

  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "23.11";
    nixpkgs.config.allowUnfree = true;

    # TODO: improve options and default/group them accordingly
    mine = {
      user = enabled;

      desktop = {
        cursor = enabled;
        fuzzel = enabled;
        hyprland = enabled;
        hyprlock = enabled;
        hyprpaper = enabled;
        waybar = enabled;
      };

      apps = {
        kitty = enabled;
        discord = enabled;
        syncthing = enabled;
      };

      tools = {
        direnv = enabled;
        git = enabled;
        home-manager = enabled;
      };

      system = {
        boot.grub = enabled;
        nix.flakes = enabled;
        shell.zsh = enabled;
        security.sudonopass = enabled;
        utils = enabled;
        video.amd = enabled;
      };

      cli-apps = {
        nixvim = enabled;
        tmux = {
          enable = true;
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/projects/nixos"
              "${user.homeDir}/projects/cloud"
            ];
          };
        };
      };

      nixos = {
        bottom = enabled;
        fonts = enabled;
        openssh = enabled;
        docker = enabled;
        firewall = enabled;
        neofetch = enabled;
        pipewire = enabled;
        bluetooth = enabled;
        gthumb = enabled;
        vlc = enabled;
        obsidian = enabled;
        screenshots = enabled;
        ollama = enabled;
        network = {
          enable = true;
          hostname = "c137";
          applet = true;
        };
      };
      home = {
        firefox = enabled;
        chrome = enabled;
        brave = enabled;
      };
    };
  };

}
