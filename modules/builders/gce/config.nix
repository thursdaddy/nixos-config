{ inputs, ... }:
{
  configurations.nixos.gce.module =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        "${inputs.nixpkgs}/nixos/modules/virtualisation/google-compute-image.nix"
      ];

      config = {
        system.stateVersion = "25.11";
        
        nix = {
          settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
        };

        mine = {
          base.networking.hostName = "";
          base.sops.ageKeyFile = {
            path = "/var/lib/sops-age/keys.txt";
            # We can use GCP Secret Manager instead of SSM later, but keeping this for now
            # if we still use AWS SSM for the age key.
            ageKeyInGCP = {
              enable = true;
              secretName = "sops-age-key";
            };
          };
          services.tailscale = {
            enable = true;
            sopsSecret = "tailscale/CLOUDBOX_AUTH_KEY";
            useRoutingFeatures = "client";
            extraUpFlags = [ "--accept-routes" ];
          };
        };

        services.openssh = {
          enable = true;
          settings.PermitRootLogin = lib.mkForce "prohibit-password";
        };

        security.googleOsLogin.enable = lib.mkForce false;

        users.users.root = {
          openssh.authorizedKeys = {
            keyFiles = [ inputs.ssh-keys.outPath ];
          };
        };

        environment.systemPackages = with pkgs; [
          neovim
          git
        ];
      };
    };
}
