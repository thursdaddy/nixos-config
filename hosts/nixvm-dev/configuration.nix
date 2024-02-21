{ config, pkgs, inputs, username, ... }: {

  imports =
    [
      inputs.home-manager.nixosModules.home-manager
      ./hardware-configuration.nix
      ../../modules/nixos/import.nix
    ];

  config = {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # https://discourse.nixos.org/t/problems-after-switching-to-flake-system/24093/8
    nix.nixPath = [ "/etc/nix/path" ];
    nix.registry.nixpkgs.flake = inputs.nixpkgs;

    environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit username; inherit inputs; };
    home-manager.users.${username}.imports = [ ./home.nix ];

    boot.loader.grub.enable = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.grub.device = "nodev";

    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.requestEncryptionCredentials = true;

    services.zfs.autoScrub.enable = true;

    networking.hostId = "adc83a82";
    networking.hostName = "nixvm-dev";
    networking.networkmanager.enable = true;
    networking.firewall.enable = false;

    # Set your time zone.
    time.timeZone = "America/Phoenix";

    system.stateVersion = "23.11";

    myopt.git.enable = true;
    myopt.docker.enable = true;

  };

}
