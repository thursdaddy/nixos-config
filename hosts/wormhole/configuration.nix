{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.mine) user;
  inherit (lib.thurs) enabled;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
    ../../modules/shared/import.nix
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
      };

      container = {
        syncthing = {
          enable = true;
          subdomain = "sync-wormhole";
          volumePaths = [
            "${user.homeDir}/projects:/projects"
            "${user.homeDir}/documents/notes/:/notes"
          ];
        };
        traefik = {
          enable = true;
          awsEnvKeys = true;
          domainName = "thurs.pw";
        };
        qemu-guest = enabled;
      };

      cli-tools = {
        bottom = enabled;
        direnv = enabled;
        just = enabled;
        fastfetch = enabled;
        nixvim = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
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
        prometheus = {
          enable = true;
          exporters = {
            node = enabled;
          };
        };
        tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
        };
      };

      system = {
        boot = {
          binfmt = enabled;
          grub = enabled;
        };
        networking = {
          networkd = {
            enable = true;
            hostname = "wormhole";
          };
          firewall = enabled;
        };
        nfs-mounts = {
          enable = true;
          mounts = {
            "/backups" = {
              device = "192.168.10.12:/fast/backups/";
            };
          };
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        services = {
          openssh = enabled;
        };
        utils = {
          dev = true;
          sysadmin = true;
        };
      };
    };
  };
}
