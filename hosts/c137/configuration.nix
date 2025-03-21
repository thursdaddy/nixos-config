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
    inputs.nixos-thurs.nixosModules.configs
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        ghToken = enabled;
        shell.package = pkgs.fish;
      };

      home-manager = {
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
        bitwarden = enabled;
        brave = enabled;
        chromium = enabled;
        discord = enabled;
        element = enabled;
        firefox = enabled;
        flycast = enabled;
        freecad = enabled;
        ghostty = enabled;
        gimp = enabled;
        gthumb = enabled;
        inkscape = enabled;
        keybase = enabled;
        keymapp = enabled;
        obsidian = enabled;
        proton = enabled;
        prusa-slicer = enabled;
        puddletag = enabled;
        steam = enabled;
        syncthing = {
          enable = true;
          isNix = true;
        };
        vivaldi = enabled;
        vlc = enabled;
        vscodium = enabled;
      };

      cli-tools = {
        ansible = enabled;
        charm-freeze = enabled;
        bottom = enabled;
        direnv = enabled;
        just = enabled;
        ncmpcpp = enabled;
        ntfy = enabled;
        fastfetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          requires.unlock = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
        vagrant = enabled;
      };

      container = {
        settings = {
          configPath = "${user.homeDir}/configs";
        };
        traefik = {
          enable = true;
          awsEnvKeys = true;
          domainName = "thurs.pw";
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
        swaync = enabled;
        systemd = enabled;
        waybar = enabled;
      };

      services = {
        beszel = {
          enable = true;
          isAgent = true;
        };
        docker = {
          enable = true;
          scripts.check-versions = true;
        };
        mpd = enabled;
        ollama = enabled;
        prometheus = {
          enable = true;
          exporters = {
            node = enabled;
            smartctl = enabled;
            zfs = enabled;
          };
        };
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
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
          index = enabled;
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
        utils = {
          dev = true;
          sysadmin = true;
        };
        video.amd = enabled;
        virtualisation = {
          libvirtd = enabled;
        };
      };
    };
  };
}
