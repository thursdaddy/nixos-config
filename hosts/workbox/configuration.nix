{ lib, config, pkgs, inputs, ... }:
let
  inherit (config.mine) user;
  inherit (lib.thurs) enabled;
in
{
  imports = [
    inputs.nixos-thurs.nixosModules.configs
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
        audiobookshelf = enabled;
        commafeed = enabled;
        gitlab = enabled;
        gitlab-runner = enabled;
        grafana = enabled;
        grocy = enabled;
        hoarder = enabled;
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
          domainName = config.nixos-thurs.localDomain;
        };
        vaultwarden = enabled;
      };

      services = {
        beszel = {
          enable = true;
          isHub = true;
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
          extraUpFlags = [ "--advertise-routes=192.168.20.0/24" ];
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
