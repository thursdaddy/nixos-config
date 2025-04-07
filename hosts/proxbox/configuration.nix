{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (config.mine) user;
  inherit (lib.thurs) enabled;
in
{
  imports = [
    ./hardware-configuration.nix
    ./stage1-boot.nix
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
    ../../overlays/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    services.proxmox-ve = {
      enable = true;
      ipAddress = "192.168.10.120";
    };

    nixpkgs.overlays = [
      inputs.proxmox-nixos.overlays.x86_64-linux
    ];

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
              "${user.homeDir}/"
            ];
          };
        };
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

      container = {
        gitlab-runner = enabled;
        open-webui = enabled;
        traefik = {
          enable = true;
          awsEnvKeys = true;
          domainName = "thurs.pw";
        };
      };

      services = {
        alloy = enabled;
        beszel = {
          enable = true;
          isAgent = true;
        };
        docker = {
          enable = true;
          scripts.check-versions = true;
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
      };

      system = {
        boot = {
          binfmt = enabled;
          systemd = enabled;
        };
        networking = {
          networkd = {
            enable = true;
            hostname = "proxbox1";
          };
          firewall = enabled;
          forwarding.ipv4 = true;
          resolved = enabled;
        };
        nfs-mounts = {
          enable = true;
          mounts = {
            "/backups" = {
              device = "192.168.10.12:/fast/backups/workbox";
            };
          };
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        services = {
          openssh = enabled;
          vm-wol = enabled;
        };
        utils = {
          dev = true;
          sysadmin = true;
        };
        video.amd = enabled;
      };
    };
  };
}
