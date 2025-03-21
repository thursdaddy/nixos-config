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
        alertmanager = enabled;
        audiobookshelf = enabled;
        commafeed = enabled;
        gitlab = enabled;
        gitlab-runner = enabled;
        grafana = enabled;
        grocy = enabled;
        hoarder = enabled;
        influxdb = enabled;
        open-webui = enabled;
        prometheus = enabled;
        syncthing = {
          enable = true;
          subdomain = "sync-workbox";
          volumePaths = [
            "${user.homeDir}/projects:/projects"
            "${user.homeDir}/documents/notes/:/notes"
          ];
        };
        teslamate = enabled;
        thelounge = enabled;
        traefik = {
          enable = true;
          awsEnvKeys = true;
          domainName = "thurs.pw";
        };
        vaultwarden = enabled;
      };

      services = {
        alloy = enabled;
        beszel = {
          enable = true;
          isHub = true;
          isAgent = true;
        };
        docker = {
          enable = true;
          scripts.check-versions = true;
        };
        grafana-ntfy = enabled;
        loki = enabled;
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
        boot = {
          binfmt = enabled;
          systemd = enabled;
        };
        networking = {
          networkd = {
            enable = true;
            hostname = "workbox";
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
          index = enabled;
        };
        services = {
          openssh = enabled;
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
