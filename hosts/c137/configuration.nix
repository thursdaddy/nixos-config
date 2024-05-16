{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in
{
  imports = [
    inputs.nixos-thurs.nixosModules.c137Containers
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "23.11";

    # find a better place for this
    sops.secrets."github/TOKEN" = mkIf config.mine.tools.sops.enable {
      owner = "${user.name}";
    };

    mine = {
      user = {
        enable = true;
        home-manager = true;
      };

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
        keymapp = enabled;
        sops = {
          enable = true;
          requires.unlock = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + " /encrypted/main.yaml ");
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

      services = {
        bluetooth = {
          enable = true;
          applet = true;
        };
        fix-suspend = enabled;
        input-remapper = enabled;
        keyring = enabled;
        openssh = enabled;
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
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
          docker = {
            enable = true;
            scripts.check-versions = true;
          };
          libvirtd = enabled;
        };
      };

      cli-apps = {
        neofetch = enabled;
        nixvim = enabled;
        ollama = enabled;
        protonvpn = enabled;
      };
    };
  };
}

