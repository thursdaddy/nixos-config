{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  user = config.mine.user;

in {

  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/import.nix
    ../../modules/home/import.nix
  ];

  config = {
    system.stateVersion = "23.11";
    nixpkgs.config.allowUnfree = true;

    boot.loader.grub.enable = true;
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.grub.device = "nodev";

    security.sudo.extraRules = [{
      users = [ "${user.name}" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages  = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
      ];
    };

    environment.systemPackages = [
      pkgs.glxinfo
    ];

    networking.firewall.allowedTCPPorts = [ 8384 22000 ];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];

    # TODO: improve options and default/group them accordingly
    mine = {
      user = enabled;

      desktop = {
        hyprland = enabled;
        hyprlock = enabled;
        hyprpaper = enabled;
      };

      apps = {
        kitty = enabled;
        discord = enabled;
      };

      tools = {
        direnv = enabled;
        git = enabled;
        home-manager = enabled;
      };

      system = {
        nix.flakes = enabled;
        shell.zsh = enabled;
      };

      cli-apps = {
        nixvim = enabled;
        tmux = {
          enable = true;
          sessionizer = {
            enable = true;
            searchPaths = [
              "${user.homeDir}/projects/nixos"
              "${user.homeDir}/projects/cloud"
            ];
          };
        };
      };

      nixos = {
        bottom = enabled;
        fonts = enabled;
        openssh = enabled;
        docker = enabled;
        firewall = enabled;
        neofetch = enabled;
        pipewire = enabled;
        bluetooth = enabled;
        gthumb = enabled;
        vlc = enabled;
        obsidian = enabled;
        utils = enabled;
        screenshots = enabled;
        ollama = enabled;
        network = {
          enable = true;
          hostname = "c137";
          applet = true;
        };
      };
      home = {
        syncthing = enabled;
        firefox = enabled;
        chrome = enabled;
        brave = enabled;
        cursor = enabled;
        waybar = enabled;
        fuzzel = enabled;
      };
    };
  };

}
