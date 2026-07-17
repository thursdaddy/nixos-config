_: {
  configurations.nixos.streambox.module =
    {
      lib,
      modulesPath,
      pkgs,
      ...
    }:

    {
      boot = {
        binfmt = {
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
        kernelModules = [ "i915" ];
        kernelParams = [ "i915.enable_guc=3" ];
        loader.systemd-boot.enable = true;
        loader.efi.canTouchEfiVariables = true;
      };

      swapDevices = [
        {
          device = "/swap";
          size = 6 * 1024;
        }
      ];

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };

        "/boot" = {
          device = "/dev/disk/by-label/boot";
          fsType = "vfat";
          options = [
            "fmask=0022"
            "dmask=0022"
          ];
        };

        "/mnt/pictures" = {
          device = "/dev/disk/by-uuid/0d8ac643-3b49-499f-a380-6248428ad295";
          fsType = "xfs";
        };
      };

      hardware = {
        enableRedistributableFirmware = true;
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            intel-vaapi-driver
            vpl-gpu-rt
            libvdpau-va-gl
          ];
        };
      };

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "iHD";
      };

      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "25.11";
    };
}
