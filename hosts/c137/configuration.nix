{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in
{

  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "23.11";

    sops.secrets.tailscale_auth_key = { };

    mine = {
      user = enabled;

      desktop = {
        bitwarden = enabled;
        cursor = enabled;
        fuzzel = enabled;
        hyprland = {
          enable = true;
          home = true;
        };
        hyprlock = enabled;
        hyprpaper = {
          enable = true;
          home = true;
        };
        screenshots = enabled;
        waybar = enabled;
      };

      apps = {
        brave = enabled;
        chromium = enabled;
        discord = enabled;
        gthumb = enabled;
        firefox = enabled;
        keybase = enabled;
        kitty = enabled;
        obsidian = enabled;
        syncthing = {
          enable = true;
          isNix = true;
        };
        vlc = enabled;
      };

      tools = {
        direnv = enabled;
        git = enabled;
        home-manager = enabled;
        bottom = enabled;
        sops = {
          enable = true;
          defaultSopsFile = (inputs.secrets.packages.${pkgs.system}.secrets + "/encrypted/secrets.yaml");
          ageKeyFile = "${user.homeDir}/.config/sops/age/keys.txt";
        };
      };

      services = {
        bluetooth = {
          enable = true;
          applet = true;
        };
        openssh = enabled;
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets.tailscale_auth_key.path;
          useRoutingFeatures = "client";
        };
      };

      system = {
        audio.pipewire = enabled;
        boot = {
          binfmt = enabled;
          grub = enabled;
        };
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
        virtualisation = {
          docker = enabled;
          libvirtd = enabled;
        };
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
    };
  };
}
