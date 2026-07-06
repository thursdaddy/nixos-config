{ inputs, ... }:
{
  configurations.nixos.ami.module =
    {
      pkgs,
      ...
    }:
    {
      config = {
        system.stateVersion = "25.11";
        virtualisation.diskSize = 8192;

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
            ageKeyInSSM = {
              enable = true;
              paramName = "/sops/age.key";
              region = "us-west-2";
            };
          };
          services.tailscale = {
            enable = true;
            sopsSecret = "tailscale/CLOUDBOX_AUTH_KEY";
            useRoutingFeatures = "client";
            extraUpFlags = [ "--accept-routes" ];
          };
        };

        services.openssh.enable = true;

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
