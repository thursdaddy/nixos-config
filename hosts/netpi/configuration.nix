{
  pkgs,
  lib,
  config,
  inputs,
  hostname,
  ...
}:
let
  inherit (lib.thurs) enabled;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
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
        git = enabled;
        bottom = enabled;
        just = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
      };

      container = {
        settings = {
          configPath = "/opt/configs";
        };
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
        blocky = enabled;
        docker = {
          enable = true;
          scripts.check-versions = true;
        };
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraSetFlags = [ "--advertise-routes=192.168.10.0/24,192.168.20.0/24" ];
        };
        prometheus = {
          enable = true;
          exporters.node = enabled;
        };
      };

      system = {
        networking = {
          networkmanager = {
            enable = true;
            hostname = "${hostname}";
          };
          firewall = enabled;
          forwarding.ipv4 = true;
        };
        nfs-mounts = {
          enable = true;
          mounts = {
            "/backups" = {
              device = "192.168.10.12:/fast/backups";
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
