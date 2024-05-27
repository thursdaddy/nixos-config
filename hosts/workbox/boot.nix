{ lib, pkgs, inputs, config, ... }:
let
in {
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  boot.initrd = {
    systemd.enable = true;
    kernelModules = [ "tpm_crb" "r8169" ];
    availableKernelModules = [ "ext4" "igb" ];
    systemd.emergencyAccess = "$6$LqrW7LCddFgpEu5P$YKQFUh96sq2RfB7VSxG041STkM.ZipEaJbC5cGkiCAR6dfQEUcbzqNyAb1Fqu5MHYJPuHSfpxiKcUli.Hff8Z.";
    # systemd.network = config.systemd.network;
    systemd.network.networks."10-lan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "no";
      networkConfig.Gateway = "192.168.20.1";
      networkConfig.Address = "192.168.20.108/24";
    };
    systemd.network.enable = true;
    network.ssh = {
      enable = true;
      ignoreEmptyHostKeys = true;
      authorizedKeys = config.users.users.thurs.openssh.authorizedKeys.keys;
    };
    systemd.contents = {
      "/etc/fstab".text = ''
        /dev/mapper/tpm2vpn /tpm2vpn ext4 defaults 0 2
        /tpm2vpn/var/lib/tailscale /var/lib/tailscale none bind,x-systemd.requires-mounts-for=/tpm2vpn/var/lib/tailscale
        # nofail so it doesn't order before local-fs.target and therefore systemd-tmpfiles-setup
        /dev/mapper/keystore /keystore ext4 defaults,nofail,x-systemd.device-timeout=0,ro 0 2
      '';
      "/etc/tmpfiles.d/50-ssh-host-keys.conf".text = ''
        C /etc/ssh/ssh_host_ed25519_key 0600 - - - /tpm2vpn/etc/ssh/ssh_host_ed25519_key
        C /etc/ssh/ssh_host_rsa_key 0600 - - - /tpm2vpn/etc/ssh/ssh_host_rsa_key
      '';
    };
    systemd.services.systemd-tmpfiles-setup.before = [ "sshd.service" ];
    luks.devices.keystore = {
      device = "/dev/disk/by-uuid/a9b17587-91b8-42bd-8029-53487520ffe3";
      crypttabExtraOpts = [ "tpm2-device=auto" "nofail" ];
    };
    luks.devices.tpm2vpn = {
      device = "/dev/disk/by-uuid/fbb1a9a1-f6e2-4d04-b823-1e67bc4d4aba";
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };
  };

  boot.loader.efi.canTouchEfiVariables = true;
}
