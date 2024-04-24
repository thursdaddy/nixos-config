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

    mine = {
      user = enabled;

      desktop = {
        bitwarden = enabled;
        cursor = enabled;
        fuzzel = enabled;
        hypridle = enabled;
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
        swaync = enabled;
        systemd = enabled;
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
        protonvpn = enabled;
        syncthing = {
          enable = true;
          isNix = true;
        };
        vlc = enabled;
      };

      tools = {
        bottom = enabled;
        direnv = enabled;
        git = enabled;
        home-manager = enabled;
        keymapp = enabled;
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
        fix-suspend = enabled;
        input-remapper = enabled;
        openssh = enabled;
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets.tailscale_auth_key.path;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--accept-dns=false" ];
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
        ollama = disabled;
        protonvpn = enabled;
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
    };
  };
}
