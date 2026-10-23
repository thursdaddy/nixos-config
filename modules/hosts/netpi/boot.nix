_: {
  configurations.nixos.netpi.module =
    { config, pkgs, ... }:
    {
      boot = {
        initrd.allowMissingModules = true;
        kernel.sysctl = {
          "vm.mmap_rnd_bits" = 24;
        };
        kernelPackages = pkgs.rpi4KernelPackages;

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
      hardware.raspberry-pi.configtxt.deviceTreeOverlays."board-type=0x11" = [
        {
          rpi-poe-plus = { };
        }
      ];

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
