_: {
  configurations.nixos.jupiter.module =
    {
      lib,
      modulesPath,
      ...
    }:

    {
      boot = {
        binfmt = {
          emulatedSystems = [ "aarch64-linux" ];
          preferStaticEmulators = true;
        };
        initrd = {
          availableKernelModules = [
            "ata_piix"
            "uhci_hcd"
            "virtio_pci"
            "virtio_scsi"
            "sd_mod"
            "sr_mod"
          ];
          kernelModules = [ ];
        };
        extraModulePackages = [ ];
        kernelModules = [ "kvm-amd" ];
        loader.grub = {
          enable = true;
          useOSProber = false;
          efiSupport = true;
          efiInstallAsRemovable = true;
          device = "nodev";
        };
      };

      swapDevices = [
        {
          device = "/swap";
          size = 6 * 1024;
        }
      ];

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXROOT";
          fsType = "ext4";
        };

        "/boot" = {
          device = "/dev/disk/by-label/NIXBOOT";
          fsType = "vfat";
          options = [
            "fmask=0022"
            "dmask=0022"
          ];
        };
      };

      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "24.11";
    };
}
