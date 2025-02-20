{ lib, pkgs, inputs, ... }:
let
  inherit (lib.thurs) enabled;
in
{
  imports = [
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
    ./hardware-configuration.nix
    ../../overlays/unstable
    ../../modules/nixos/import.nix
    ../../modules/shared/import.nix
  ];

  config = {
    system.stateVersion = "24.11";

    services.journald.extraConfig = ''
      SystemMaxUse=1G
    '';

    nix.settings.trusted-users = [ "ssm-user" "@wheel" ];

    environment.systemPackages = with pkgs; [
      neovim
    ];

    mine = {
      user = {
        enable = true;
        shell.package = pkgs.fish;
      };

      cli-tools = {
        awscli = enabled;
        bottom = enabled;
        fastfetch = enabled;
        sops = {
          enable = true;
          defaultSopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
        };
        ssm-session-manager = enabled;
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
        prometheus = {
          enable = true;
          exporters.node = enabled;
        };
        r53-updater = enabled;
        tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          extraUpFlags = [ "--accept-routes" "--accept-dns=true" ];
        };
      };

      system = {
        networking = {
          firewall = enabled;
          forwarding.ipv4 = true;
          networkd = {
            enable = true;
            hostname = "cloudbox";
          };
          resolved = enabled;
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
