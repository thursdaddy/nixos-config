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
    nixpkgs.config.allowUnfree = true;

    boot.loader.grub.enable = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.grub.device = "nodev";

    networking = {
      networkmanager.enable = true;
      hostName = "c137";
    };

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
        bottom = enabled;
        fonts = enabled;
        flakes = enabled;
        openssh = enabled;
        docker = enabled;
        firewall = enabled;
        nixvim = enabled;
        hyprland = enabled;
        neofetch = enabled;
        pipewire = enabled;
        bluetooth = enabled;
        gthumb = enabled;
        vlc = enabled;
        utils = enabled;
      };
      home = {
        home-manager = enabled;
        alacritty = enabled;
        firefox = enabled;
        chrome = enabled;
        brave = enabled;
        cursor = enabled;
        hyprland  = enabled;
        hyprlock = enabled;
        hyprpaper = enabled;
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
