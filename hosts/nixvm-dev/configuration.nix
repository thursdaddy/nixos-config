{ lib, config, pkgs, inputs, username, ... }:
with lib;
with lib.thurs; {

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

    mine = {
      git = enabled;
      home-manager = enabled;
      kde = enabled;
      firewall = enabled;
      timezone = enabled;
      openssh = enabled;
      docker = enabled;
      zsh = enabled;
      user = {
          enable = true;
          email = "thurs@pm.me";
      };
    };
  };

}
