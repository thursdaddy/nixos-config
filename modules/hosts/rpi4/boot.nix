_: {
  configurations.nixos.rpi4.module =
    { config, pkgs, ... }:
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "24.11";

      boot = {
        initrd.allowMissingModules = true;
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

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [ "noatime" ];
        };
      };

    };
}
