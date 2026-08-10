{ inputs, ... }:
{
  configurations.nixos.aarch64-iso.module =
    {
      config,
      lib,
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
      ];

      config = {
        system.stateVersion = "25.11";

        nix = {
          settings.experimental-features = [
            "nix-command"
            "flakes"
          ];
        };

        networking = {
          hostName = "iso";
        };

        services = {
          openssh.enable = true;
        };

        users.users.root = {
          initialPassword = "changeme";
          initialHashedPassword = lib.mkForce null;
          openssh.authorizedKeys = {
            keyFiles = [ inputs.ssh-keys.outPath ];
          };
        };

        environment.systemPackages = with pkgs; [
          neovim
          git
          cryptsetup
          gnupg
          pass
        ];
      };
    };
}
