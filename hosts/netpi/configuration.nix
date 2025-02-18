{ pkgs, lib, config, inputs, hostname, ... }:
let
  inherit (lib.thurs) enabled;
  inherit (config.mine) user;
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
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

      services = {
        beszel = {
          enable = true;
          isAgent = true;
        };
        docker = {
          enable = true;
          scripts.check-versions = true;
        };
        tailscale = {
          enable = true;
          authKeyFile = config.sops.secrets."tailscale/AUTH_KEY".path;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--advertise-routes=192.168.20.0/24" ];
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
          unfree = enabled;
          flakes = enabled;
        };
        services = {
          openssh = enabled;
        };
        utils = enabled;
      };
    };
  };
}
