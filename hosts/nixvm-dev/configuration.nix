{ ... }: {

  imports =
    [
      ./hardware-configuration.nix
      ../shared
      ../../modules/nixos/user
      ../../modules/nixos/virtualisation/docker
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  # X Server
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  system.stateVersion = "23.11";

  programs.zsh.shellAliases = {
      "ds" = "docker ps -qa";
  };
}
