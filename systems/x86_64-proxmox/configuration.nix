{ pkgs, modulesPath, ... }:

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
}
