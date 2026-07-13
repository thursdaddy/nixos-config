{ inputs, ... }:
{
  configurations.nixos.x86_64-iso.module =
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

        systemd.network.enable = true;

        boot.loader.systemd-boot.enable = lib.mkDefault true;
        boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
        boot.loader.grub.enable = lib.mkDefault false;

        networking = {
          hostName = "iso";
          useNetworkd = true;
          dhcpcd.enable = false;
          interfaces.enp3s0.ipv4.addresses = [
            {
              address = "192.168.10.222";
              prefixLength = 24;
            }
          ];
          defaultGateway = {
            address = "192.168.10.1";
            interface = "enp3s0";
          };
          nameservers = [
            "192.168.10.53"
          ];
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
        ];
      };
    };
}
