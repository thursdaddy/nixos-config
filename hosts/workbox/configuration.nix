{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  inherit (config.mine) user;

in
{
  imports = [
    ./hardware-configuration.nix
    ./stage1-boot.nix
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
        ghostty = enabled;
      };

      cli-tools = {
        bottom = enabled;
        direnv = enabled;
        git = enabled;
        just = enabled;
        neofetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
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
        beszel = {
          enable = true;
          isHub = true;
          isAgent = true;
        };
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
          useRoutingFeatures = "client";
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
        };
        upsnap = enabled;
      };

      system = {
        audio.pipewire = enabled;
        boot = {
          binfmt = enabled;
          systemd = enabled;
        };
        networking = {
          networkd = {
            enable = true;
            hostname = "workbox";
          };
          firewall = disabled;
          forwarding.ipv4 = true;
          resolved = enabled;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        services = {
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
        };
      };
    };
  };
}
