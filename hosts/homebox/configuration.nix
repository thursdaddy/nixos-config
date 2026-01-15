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
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
    ../../modules/home/import.nix
    ../../overlays/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    nixpkgs.config.permittedInsecurePackages = [
      "python3.12-ecdsa-0.19.1"
    ];

    # I don't know why but without this $HOME is defaulting to "/" instead of "/home/thurs" and I get errors
    environment.variables = {
      HOME = "/home/thurs";
    };

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        shell.package = pkgs.zsh;
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

      container = {
        attic-db = enabled;
        traefik = {
          enable = true;
          awsEnvKeys = true;
          domainName = "thurs.pw";
        };
      };

      cli-tools = {
        attic = enabled;
        bottom = enabled;
        crush = enabled;
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
        alloy = enabled;
        atticd = enabled;
        beszel = {
          enable = true;
          isAgent = true;
        };
        blocky = enabled;
        docker = enabled;
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
                "/var/lib:/fake/var/lib:ro"
                "/var/run/docker.sock:/var/run/docker.sock"
              ];
            };
          };
        };
        home-assistant = enabled;
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraSetFlags = [ "--advertise-routes=192.168.10.0/24" ];
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
          substituters = enabled;
        };
        services = {
          openssh = enabled;
          bluetooth = enabled;
          sleep-on-lan = enabled;
        };
        utils = {
          dev = true;
          sysadmin = true;
        };
      };
    };
  };
}
