_: {
  configurations.nixos.kepler.module =
    {
      lib,
      modulesPath,
      ...
    }:

    {
      boot = {
        binfmt.emulatedSystems = [ "aarch64-linux" ];
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

        "/opt" = {
          device = "/dev/disk/by-label/CONFIGS";
          fsType = "ext4";
        };
      };

      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "24.11";
    };
}
