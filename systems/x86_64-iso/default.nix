{ pkgs, ... }: {
  imports = [ ];

  config = {
    system.stateVersion = "24.11";

    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
    };

    hardware.cpu.amd.updateMicrocode = true;
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;

    networking = {
      hostId = "00000000";
      defaultGateway = "192.168.20.1";
      nameservers = [ "192.168.10.57" "192.168.10.201" ];
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
