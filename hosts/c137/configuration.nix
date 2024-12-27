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
    system.stateVersion = "24.11";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        ssh-config = enabled;
        ghToken = enabled;
      };

      apps = {
        bitwarden = enabled;
        brave = enabled;
        chromium = enabled;
        discord = enabled;
        element = enabled;
        firefox = enabled;
        gimp = enabled;
        gthumb = enabled;
        inkscape = enabled;
        keybase = enabled;
        kitty = enabled;
        obsidian = enabled;
        proton = enabled;
        prusa-slicer = enabled;
        puddletag = enabled;
        steam = enabled;
        syncthing = {
          enable = true;
          isNix = true;
        };
        vlc = enabled;
        vscodium = enabled;
      };

      cli-tools = {
        ansible = enabled;
        ncmpcpp = enabled;
        bottom = enabled;
        direnv = enabled;
        git = enabled;
        just = enabled;
        neofetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          requires.unlock = true;
          defaultSopsFile = (inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml");
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
        cursor = enabled;
        fuzzel = enabled;
        hypridle = enabled;
        hyprland = {
          enable = true;
          home = true;
        };
        hyprlock = enabled;
        hyprpaper = enabled;
        screenshots = enabled;
        sddm = enabled;
        swaync = enabled;
        systemd = enabled;
        waybar = enabled;
      };

      services = {
        mpd = enabled;
        ollama = enabled;
        prometheus = {
          enable = true;
          exporters.node = enabled;
          exporters.smartctl = enabled;
          exporters.zfs = enabled;
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
          sleep-on-lan = enabled;
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

