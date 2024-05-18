{ lib, pkgs, ... }:
with lib;
with lib.thurs; {

  imports = [
    ../../modules/import.nix
  ];

  config = {

    system.stateVersion = "23.11";

    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    networking = {
      hostId = "00000000";
      defaultGateway = "192.168.20.1";
      nameservers = [ "192.168.20.80" ];
      interfaces.eth0.ipv4.addresses = [{
        address = "192.168.20.222";
        prefixLength = 24;
      }];
    };

    systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

    users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs" ];

    environment.systemPackages = with pkgs; [
      neovim
      git
    ];

  };
}
