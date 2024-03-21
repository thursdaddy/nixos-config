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

    mine = {
      user = enabled;

      desktop = {
        cursor = enabled;
        fuzzel = enabled;
        hyprland = enabled;
        hyprlock = enabled;
        hyprpaper = enabled;
        screenshots = enabled;
        waybar = enabled;
      };

      apps = {
        discord = enabled;
        gthumb = enabled;
        kitty = enabled;
        obsidian = enabled;
        syncthing = enabled;
        vlc = enabled;
      };

      tools = {
        direnv = enabled;
        git = enabled;
        home-manager = enabled;
        bottom = enabled;
      };

      services = {
        bluetooth = enabled;
        openssh = enabled;
      };

      system = {
        audio.pipewire = enabled;
        boot.grub = enabled;
        fonts = enabled;
        networking = {
          enable = true;
          firewall = enabled;
          hostname = "c137";
          applet = true;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        security.sudonopass = enabled;
        shell.zsh = enabled;
        utils = enabled;
        video.amd = enabled;
        virtualisation.docker = enabled;
      };

      cli-apps = {
        neofetch = enabled;
        nixvim = enabled;
        ollama = enabled;
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
      # TODO: Get home-manager installed packages to show up in Spotlight / Applications
      home = {
        brave = enabled;
        chrome = enabled;
        firefox = enabled;
      };
    };
  };

}
