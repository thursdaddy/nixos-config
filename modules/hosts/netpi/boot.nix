_: {
  configurations.nixos.netpi.module =
    { config, pkgs, ... }:
    {
      boot = {
        initrd.allowMissingModules = true;
        kernel.sysctl = {
          "vm.mmap_rnd_bits" = 24;
        };
        kernelPackages = let
          rpiKernel = pkgs.callPackage "${pkgs.path}/pkgs/os-specific/linux/kernel/linux-rpi.nix" {
            kernelPatches = with pkgs.linuxKernel.kernelPatches; [
              bridge_stp_helper
              request_key_helper
            ];
            rpiVersion = 4;
          };
        in pkgs.linuxKernel.packagesFor rpiKernel;

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
