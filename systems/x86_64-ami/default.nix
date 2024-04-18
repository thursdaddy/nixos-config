{ lib, pkgs, inputs, config, ... }:
with lib.thurs;
{

  imports = [
    ../../modules/nixos/import.nix
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
  ];

  config = {
    system.stateVersion = "23.11";

    mine = {
      nix = {
        flakes = enabled;
      };

      services.tailscale = {
        enable = true;
        authKeyFile = config.sops.secrets.tailscale_auth_key.path;
        useRoutingFeatures = "client";
        extraUpFlags = [ "--accept-routes" "--accept-dns=true" ];
      };

      services = {
        ssm-agent = enabled;
        openssh = {
          enable = true;
          root = true;
        };
      };

      system = {
        ami = true;
        networking = {
          resolved = enabled;
          forwarding.ipv4 = true;
        };
        utils = enabled;
      };

      tools = {
        sops = {
          enable = true;
          defaultSopsFile = (inputs.secrets.packages.${pkgs.system}.secrets + "/encrypted/tailscale_auth.yaml");
        };
      };
    };

    environment.systemPackages = with pkgs; [
      neovim
      git
      awscli2
    ];

    sops.secrets.tailscale_auth_key = { };

    systemd.services.decrypt-sops = {
      description = "Decrypt sops secrets";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "2s";
      };
      script = config.system.activationScripts.setupSecrets.text;
    };

    systemd.services.tailscaled-autoconnect-reload = {
      after = [ "decrypt-sops.service" ];
      partOf = [ "decrypt-sops.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        ${config.systemd.package}/bin/systemctl restart tailscaled-autoconnect
      '';
    };
  };
}
