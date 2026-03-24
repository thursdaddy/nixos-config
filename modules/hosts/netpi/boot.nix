_: {
  configurations.nixos.netpi.module =
    { config, pkgs, ... }:
    {
      boot = {
        initrd.allowMissingModules = true;
        kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
        initrd.availableKernelModules = [
          "xhci_pci"
          "usbhid"
          "usb_storage"
        ];
        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };
      };

      hardware.enableRedistributableFirmware = true;
      hardware.raspberry-pi."4".poe-plus-hat.enable = true;

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [ "noatime" ];
        };
      };

      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "24.11";
    };
}
