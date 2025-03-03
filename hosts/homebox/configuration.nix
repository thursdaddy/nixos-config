{ lib, config, pkgs, inputs, ... }:
let
  inherit (lib.thurs) enabled;
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

    fileSystems."/backups" = {
      device = "192.168.20.12:/fast/backups";
      fsType = "nfs";
      options = [ "auto" "rw" "defaults" "_netdev" ];
    };

    mine = {
      user = {
        enable = true;
        home-manager = enabled;
        shell.package = pkgs.fish;
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
          extraUpFlags = [ "--advertise-routes=192.168.20.0/24" ];
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
