{ lib, config, pkgs, inputs, ... }:
with lib.thurs;
let

  user = config.mine.user;

in
{
  imports = [
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "24.05";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        ssh-config = enabled;
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

      cli-tools = {
        bottom = enabled;
        direnv = enabled;
        git = {
          enable = true;
          ghToken = true;
        };
        neofetch = enabled;
        nixvim = enabled;
        protonvpn = enabled;
        sops = {
          enable = true;
          requires.unlock = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/main.yaml");
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

      services = {
        ollama = enabled;
        prometheus = {
          enable = true;
          exporters = {
            node = {
              enable = true;
            };
          };
        };
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--accept-dns=true" ];
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
          networkmanager = {
            enable = true;
            applet = true;
            hostname = "c137";
          };
          firewall = enabled;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        security.sudonopass = enabled;
        services = {
          bluetooth = {
            enable = true;
            applet = true;
          };
          fix-suspend = enabled;
          input-remapper = enabled;
          keyring = enabled;
          openssh = enabled;
        };
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

      tools = {
        keymapp = enabled;
      };
    };
  };
}

