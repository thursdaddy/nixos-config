{ lib, inputs, config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/nixos/user
      ../../modules/nixos/programs/zsh
      ../../modules/nixos/virtualisation/docker
      ../shared
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # ZFS boot
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = true;

  # ZFS AutoScrub
  services.zfs.autoScrub.enable = true;

  # head -c4 /dev/urandom | od -A none -t x4
  networking.hostId = "13e5ce87";
  networking.hostName = "nixvm";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Phoenix";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  system.stateVersion = "23.11";

}
