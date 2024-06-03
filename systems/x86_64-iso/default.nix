{ lib, pkgs, inputs, ... }:
with lib;
with lib.thurs; {

  imports = [
  ];

  config = {
    system.stateVersion = "24.05";

    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    hardware.cpu.amd.updateMicrocode = true;
    # boot.kernelPackages = pkgs.linuxPackages_latest;
    # boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_7;
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    networking = {
      hostId = "00000000";
      defaultGateway = "192.168.20.1";
      nameservers = [ "192.168.20.51" "192.168.20.52" ];
      interfaces.eth0.ipv4.addresses = [{
        address = "192.168.20.222";
        prefixLength = 24;
      }];
    };

    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs" ];

    environment.systemPackages = with pkgs; [
      neovim
      git
    ];
  };
}
