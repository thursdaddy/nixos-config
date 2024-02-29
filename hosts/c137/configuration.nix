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
      networkmanager.enable = true;
      hostName = "c137";
      hostId = "80f1eef1";
    };

    # TODO: improve options and default/group them accordingly
    mine = {
      nixos = {
        user = enabled;
        fonts = enabled;
        flakes = enabled;
        openssh = enabled;
        docker = enabled;
        firewall = enabled;
        nixvim = enabled;
        hyprland = enabled;
        sddm = {
          enable = true;
        };
      };
      home = {
        home-manager = enabled;
        hyprland  = enabled;
        hyprlock = enabled;
        waybar = enabled;
        git = enabled;
        zsh = enabled;
        tmux = enabled;
      };
    };
  };

}
