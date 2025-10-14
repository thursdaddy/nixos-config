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

    security.sudo-rs.enable = true;

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
        gitlab-runner = {
          enable = true;
          runners = {
            docker = {
              tags = [
                "${config.networking.hostName}"
                "netpi"
              ];
            };
          };
        };
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraSetFlags = [ "--advertise-routes=192.168.10.0/24" ];
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
