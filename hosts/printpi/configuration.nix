{ config, pkgs, lib, inputs, ... }:
let
  inherit (lib.thurs) enabled;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    inputs.nixos-thurs.nixosModules.configs
    ./hardware-configuration.nix
    ../../overlays/import.nix
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    services.rpcbind.enable = true;

    fileSystems."/opt/configs" = {
      device = "192.168.10.12:/fast/configs";
      fsType = "nfs";
      options = [ "auto" "rw" "defaults" "_netdev" "x-systemd.automount" ];
    };

    environment.systemPackages = with pkgs; [
      neovim
    ];

    mine = {
      user = {
        enable = true;
        shell.package = pkgs.fish;
      };

      cli-tools = {
        bottom = enabled;
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
          domainName = config.nixos-thurs.localDomain;
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
        octoprint = enabled;
        prometheus = {
          enable = true;
          exporters.node = enabled;
        };
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
        };
      };

      system = {
        networking = {
          networkmanager = {
            enable = true;
            hostname = "printpi";
          };
          firewall = enabled;
          forwarding.ipv4 = true;
        };
        nix = {
          unfree = enabled;
          flakes = enabled;
        };
        security.sudonopass = enabled;
        services = {
          openssh = enabled;
        };
      };
    };
  };
}
