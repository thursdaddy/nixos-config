{ lib, config, ... }:
with lib;
with lib.thurs;
let user = config.mine.nixos.user ;
in {

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

    services.xserver.videoDrivers = [ "amdgpu" ];

    nixpkgs.config.allowUnfree = true;

    security.sudo.extraRules = [{
      users = [ "${user.name}" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];

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
        hyprpaper = enabled;
        neofetch = enabled;
        pipewire = enabled;
        bluetooth = enabled;
        gthumb = enabled;
        vlc = enabled;
        sddm = enabled;
        utils = enabled;
      };
      home = {
        home-manager = enabled;
        alacritty = enabled;
        firefox = enabled;
        chrome = enabled;
        brave = enabled;
        hyprland  = enabled;
        hyprlock = enabled;
        waybar = enabled;
        fuzzel = enabled;
        git = enabled;
        zsh = enabled;
        tmux = enabled;
        discord = enabled;
      };
    };
  };

}
