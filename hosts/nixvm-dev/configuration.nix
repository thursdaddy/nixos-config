{ config, pkgs, inputs, username, ... }: {

  imports =
    [
      ./hardware-configuration.nix
      ../../modules/import.nix
    ];

  config = {
    system.stateVersion = "23.11";

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

    mine.firewall.enable = true;
    mine.timezone.enable = true;
    mine.openssh.enable = true;
    mine.docker.enable = true;
    mine.git.enable = true;
    mine.zsh.enable = true;
    #mine.home-manager = true;

  };

}
