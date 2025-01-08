{ pkgs, ... }: {

  imports = [ ];

  config = {
    system.stateVersion = "24.11";

    hardware.enableRedistributableFirmware = true;

    boot = {
      kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
      initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
      loader = {
        grub.enable = false;
        generic-extlinux-compatible.enable = true;
      };
    };

    nixpkgs.overlays = [
      (final: super: {
        makeModulesClosure = x:
          super.makeModulesClosure (x // { allowMissing = true; });
      })
    ];

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
        options = [ "noatime" ];
      };
    };

    networking = {
      hostId = "00000000";
      defaultGateway = "192.168.20.1";
      nameservers = [ "192.168.20.52" "192.168.20.53" ];
      interfaces.eth0.ipv4.addresses = [{
        address = "192.168.20.222";
        prefixLength = 24;
      }];
    };

    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMsmsLubwu6s0wkeKTsM2EIuJRKFsg2nZdRCVtQHk9LT thurs" ];

    environment.systemPackages = with pkgs; [
      neovim
    ];
  };
}
