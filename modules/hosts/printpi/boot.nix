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
        kernel.sysctl = {
          "vm.mmap_rnd_bits" = 24;
        };
        kernelPackages = pkgs.rpi4KernelPackages;
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
      hardware.raspberry-pi.configtxt.deviceTreeOverlays."board-type=0x11" = [
        {
          rpi-poe-plus = { };
        }
      ];

      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "24.11";
    };
}
