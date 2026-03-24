_: {
  configurations.nixos.proxbox1.module =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot = {
        extraModulePackages = [ ];
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "usb_storage"
            "usbhid"
            "sd_mod"
          ];
          kernelModules = [ ];
        };
        kernelModules = [ "kvm-amd" ];
        loader.systemd-boot = {
          enable = true;
          consoleMode = "auto";
        };
        loader.efi.canTouchEfiVariables = true;
        supportedFilesystems = [ "zfs" ];
      };

      networking = {
        hostId = "5cdce191";
        interfaces = {
          vmbr0.useDHCP = true;
          enp2s0.wakeOnLan.enable = true;
        };
        bridges = {
          "vmbr0" = {
            interfaces = [ "eno1" ];
          };
        };
      };

      swapDevices = [ ];

      fileSystems = {
        "/" = {
          device = "NIX/root";
          fsType = "zfs";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/B503-FC0B";
          fsType = "vfat";
          options = [
            "fmask=0022"
            "dmask=0022"
          ];
        };
        "/pool" = {
          device = "proxpool1/main";
          neededForBoot = false;
          fsType = "zfs";
          encrypted.keyFile = "/keystore/workbox.key";
        };
      };

      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      nixpkgs.hostPlatform = "x86_64-linux";
      system.stateVersion = "24.11";
    };
}
