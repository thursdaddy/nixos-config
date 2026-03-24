_: {
  configurations.nixos.rpi4.module =
    { config, pkgs, ... }:
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "24.11";

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

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [ "noatime" ];
        };
      };

    };
}
