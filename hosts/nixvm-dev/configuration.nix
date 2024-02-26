{ lib, ... }:
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

    networking = {
      hostId = "adc83a82";
      hostName = "nixvm-dev";
      networkmanager.enable = true;
    };

    mine = {
      nixos = {
        user = enabled;
        flakes = enabled;
        openssh = enabled;
        docker = enabled;
        #kde = enabled;
        firewall = enabled;
        nixvim = enabled;
      };
      home = {
        home-manager = enabled;
        git = enabled;
        zsh = enabled;
        tmux = enabled;
      };
    };
  };

}
