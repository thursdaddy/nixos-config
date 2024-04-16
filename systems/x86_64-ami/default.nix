{ pkgs, inputs, config, ... }:
{

  imports = [
    ../../modules/nixos/import.nix
    (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
  ];

  config = {
    system.stateVersion = "23.11";

    ec2.hvm = true;
    services.amazon-ssm-agent.enable = true;

    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDf3iS7lXUebJun3jQ3EJWkFoZcCrfaaAJaZWE1FFqEkLUFXhuBxITRXXqVyPjBHrY52RoAmg6RQejQDBcyV4sSs1IWMhHr50RzdM1FXGJunel6l3gvg36vUZ8OU+KU3N7E41it8we8IvV+QeDfV3QhXWAvCHIwA7UdTha00YDPaZxmZPOOnq0tE16d/9u8F8jYyuuBPwtE8PilaY5q6HI151hNTxb7vxru3H6faUjO1JKnY3UjU32FyTkz4o4IkvmdAWoft38gmtdr1VU0Fg/aZ8H6ltUPGdj8d/Nr6iUvxT41cIMmPNEeKJQ1mrVlIZ2AMN9LggLVIx02LbIQ2Pabbvyhq4FHCTztYkYjPnBBEbqKcsSMObqzGhQQxiOkrbVjmx8qei0NvnmPUHpoPCKzcJhApTBRKd7Pck2+nl56BJG9YqnELjAiogolELyJgnB88g4zKKGi/o21GW1vRXGMMn/gCWkiPBjBlBzYjGDaVFfMLc9GVhVfgnJFFiVZmMk= thurs@nixos"
    ];

    environment.systemPackages = with pkgs; [
      neovim
      git
      sops
    ];

    sops = {
      defaultSopsFile = (inputs.secrets.packages.${pkgs.system}.secrets + "/encrypted/tailscale_auth.yaml");
      secrets.tailscale_auth_key = { };
    };

    mine = {
      services.openssh.enable = true;
      services.openssh.iso = true;
      system.utils.enable = true;
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--advertise-exit-node --accept-routes" ];
    };

    #   services.resolved = {
    #     enable = true;
    #     domains = [ "~." ];
    #     fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
    #   };

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
