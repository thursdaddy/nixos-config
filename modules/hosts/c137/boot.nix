_: {
  configurations.nixos.c137.module =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot = {
        binfmt = {
          emulatedSystems = [ "aarch64-linux" ];
          preferStaticEmulators = true;
        };
        consoleLogLevel = 0;
        extraModulePackages = [ ];
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "usbhid"
            "usb_storage"
            "sd_mod"
          ];
          kernelModules = [ ];
          verbose = false;
          luks.devices = {
            "luks-rpool-nvme-CT2000P5PSSD8_22393B9712C0-part2".device =
              "/dev/disk/by-id/nvme-CT2000P5PSSD8_22393B9712C0-part2";
          };
        };
        kernelModules = [ "kvm-amd" ];
        kernelParams = [
          "quiet"
          "loglevel=3"
          "rd.systemd.show_status=false"
          "rd.udev.log_level=3"
          "udev.log_priority=3"
        ];
        loader.grub = {
          enable = true;
          useOSProber = false;
          efiSupport = true;
          efiInstallAsRemovable = true;
          device = "nodev";
        };
      };

      networking = {
        hostId = "c8cf78d0";
      };

      fileSystems = {
        "/" = {
          device = "NIXROOT/root";
          fsType = "zfs";
        };
        "/home" = {
          device = "NIXROOT/home";
          fsType = "zfs";
        };
        "/persist" = {
          device = "NIXROOT/persist";
          fsType = "zfs";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/7D91-10AC";
          fsType = "vfat";
        };
      };

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "24.11";
    };
}
