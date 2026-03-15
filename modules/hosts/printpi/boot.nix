_: {
  configurations.nixos.printpi.module =
    { pkgs, lib, ... }:
    {
      boot = {
        initrd = {
          allowMissingModules = true;
          availableKernelModules = [
            "xhci_pci"
            "usbhid"
            "usb_storage"
            "nfs"
          ];
        };
        kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };
      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [ "noatime" ];
        };
      };

      hardware.enableRedistributableFirmware = true;
      hardware.raspberry-pi."4".poe-plus-hat.enable = true;

      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "24.11";
    };
}
