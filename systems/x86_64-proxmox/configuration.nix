{ config,  pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = [
    pkgs.neovim
    pkgs.git
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];

  # isoFileSystems <- add luks (see issue dmadisetti/#34)
  boot.loader = rec {
    grub2-theme = {
      enable = true;
      icon = "white";
      theme = "whitesur";
      screen = "1080p";
      splashImage = ../../assets/backgrounds/grub.jpg;
      footer = true;
    };
  };

  isoImage.grubTheme = config.boot.loader.grub.theme;
  isoImage.splashImage = config.boot.loader.grub.splashImage;
  isoImage.efiSplashImage = config.boot.loader.grub.splashImage;
}
