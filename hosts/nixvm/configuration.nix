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

    networking = {
        networkmanager.enable = true;
        hostName = "nixvm";
        hostId = "13e5ce87";
    };

    mine = {
      nixos = {
        user = enabled;
        fonts = enabled;
        flakes = enabled;
        openssh = enabled;
        docker = enabled;
        firewall = enabled;
        nixvim = enabled;
        kde = enabled;
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
