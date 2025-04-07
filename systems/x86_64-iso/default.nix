{ pkgs, ... }:
{
  imports = [ ];

  config = {
    system.stateVersion = "24.11";

    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    hardware.cpu.amd.updateMicrocode = true;


    systemd.network.enable = true;

    networking = {
      useDHCP = true;
      useNetworkd = true;
      hostName = "nixos";
    };

    services = {
      qemuGuest.enable = true;
      openssh.enable = true;
    };

    users.users.root.initialPassword = "changeme";
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs"
    ];

    environment.systemPackages = with pkgs; [
      neovim
      git
    ];
  };
}
