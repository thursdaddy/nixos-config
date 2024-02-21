{ lib, inputs, config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../lib
      ../../modules/nixos/import.nix
      ./options.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # https://discourse.nixos.org/t/problems-after-switching-to-flake-system/24093/8
  nix.nixPath = [ "/etc/nix/path" ];
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;

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

  system.stateVersion = "23.11";

}
