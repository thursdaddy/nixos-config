{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
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

    environment.systemPackages = [
      pkgs.neovim
    ];

    mine = {
      user = {
        enable = true;
        shell.package = pkgs.fish;
      };

      cli-tools = {
        attic = enabled;
        bottom = enabled;
        fastfetch = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
      };

      container = {
        audiobookshelf = enabled;
        commafeed = enabled;
        gitlab = enabled;
        greenbook = enabled;
        grocy = enabled;
        hoarder = enabled;
        navidrome = enabled;
        open-webui = enabled;
        paperless-ngx = enabled;
        rwmarkable = enabled;
        tasktrove = enabled;
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
        attic = enabled;
        beszel = {
          enable = true;
          isAgent = true;
        };
        docker = {
          enable = true;
          scripts.check-versions = true;
        };
        gitlab-runner = {
          enable = true;
          runners = {
            docker = {
              tags = [
                "${config.networking.hostName}"
                "docker"
              ];
              dockerVolumes = [
                "/var/run/docker.sock:/var/run/docker.sock"
              ];
            };
            backup = {
              tags = [
                "${config.networking.hostName}"
                "backup"
              ];
              dockerVolumes = [
                "/backups:/backups"
                "/opt/configs:/opt/configs:ro"
                "/var/run/docker.sock:/var/run/docker.sock"
              ];
            };
          };
        };
        ollama = enabled;
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
        qemu-guest = enabled;
      };

      system = {
        boot = {
          binfmt = enabled;
          grub = enabled;
        };
        networking = {
          networkd = {
            enable = true;
            hostname = "jupiter";
          };
          firewall = enabled;
        };
        nfs-mounts = {
          enable = true;
          mounts = {
            "/backups" = {
              device = "192.168.10.12:/fast/backups/jupiter";
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
      };
    };
  };
}
