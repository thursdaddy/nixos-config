{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (lib.thurs) enabled;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ../../overlays/import.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
    ../../modules/shared/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    services.rpcbind.enable = true;
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
        nfs-mounts = {
          enable = true;
          mounts = {
            "/opt/configs" = {
              device = "192.168.10.12:/fast/configs/printpi";
              options = [
                "auto"
                "rw"
                "defaults"
                "_netdev"
                "x-systemd.automount"
              ];
            };
          };
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
