{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib.thurs) enabled;
  inherit (config.mine) user;
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
        shell.package = pkgs.fish;
      };

      cli-tools = {
        bottom = enabled;
        fastfetch = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
      };

      container = {
        alertmanager = enabled;
        grafana = enabled;
        prometheus = enabled;
        traefik = {
          enable = true;
          awsEnvKeys = true;
          domainName = "thurs.pw";
        };
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
        gitlab-runner = {
          enable = true;
          runners = {
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
        loki = enabled;
        prometheus = {
          enable = true;
          exporters = {
            node = enabled;
          };
        };
        qemu-guest = enabled;
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
            hostname = "kepler";
          };
          firewall = enabled;
        };
        nfs-mounts = {
          enable = true;
          mounts = {
            "/backups" = {
              device = "192.168.10.12:/fast/backups/kepler";
            };
          };
        };
        nix = {
          flakes = enabled;
          substituters = enabled;
          unfree = enabled;
        };
        services = {
          openssh = enabled;
        };
      };
    };
  };
}
