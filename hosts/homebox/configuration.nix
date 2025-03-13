{ lib, config, pkgs, inputs, ... }:
let
  inherit (lib.thurs) enabled;
  inherit (config.mine) user;
in
{
  imports = [
    inputs.nixos-thurs.nixosModules.configs
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
    ../../overlays/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    environment.systemPackages = [
      pkgs.esptool
    ];

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
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
              "/var/lib/"
            ];
          };
        };
      };

      apps = {
        home-assistant = enabled;
      };

      container = {
        traefik = {
          enable = true;
          awsEnvKeys = true;
          domainName = config.nixos-thurs.localDomain;
        };
      };

      cli-tools = {
        bottom = enabled;
        direnv = enabled;
        fastfetch = enabled;
        just = enabled;
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
        blocky = enabled;
        docker = enabled;
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraSetFlags = [ "--advertise-routes=192.168.10.0/24,192.168.20.0/24" ];
        };
      };

      system = {
        boot = {
          grub = enabled;
        };
        networking = {
          networkmanager = {
            enable = true;
            hostname = "homebox";
          };
          firewall = enabled;
        };
        nfs-mounts = {
          enable = true;
          mounts = {
            "/backups" = {
              device = "192.168.10.12:/fast/backups/homebox";
            };
          };
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        services = {
          openssh = enabled;
          bluetooth = enabled;
        };
        utils = {
          dev = true;
          sysadmin = true;
        };
      };
    };
  };
}
