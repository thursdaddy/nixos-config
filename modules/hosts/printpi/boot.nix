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
        kernelPackages = let
          rpiKernel = pkgs.callPackage "${pkgs.path}/pkgs/os-specific/linux/kernel/linux-rpi.nix" {
            kernelPatches = with pkgs.linuxKernel.packages.linux_rpi4.kernelPatches or pkgs.linuxKernel.kernelPatches; [
              bridge_stp_helper
              request_key_helper
            ];
            rpiVersion = 4;
          };
        in pkgs.linuxKernel.packagesFor rpiKernel;
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
