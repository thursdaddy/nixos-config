{ lib, inputs, config, pkgs, ... }:
with lib;
with lib.thurs; {

  imports = [
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

    # head -c4 /dev/urandom | od -A none -t x4
    networking.hostId = "13e5ce87";
    networking.hostName = "nixvm";

    networking.networkmanager.enable = true;

    mine = {
      git = enabled;
      home-manager = enabled;
      kde = enabled;
      firewall = enabled;
      openssh = enabled;
      zsh = enabled;
      user = {
          enable = true;
      };
    };

  };

}
