# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, modulesPath, ... }: {

  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot = {
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    loader.efi.canTouchEfiVariables = true;
    supportedFilesystems = [ "zfs" ];
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ ];
    };
  };

  # ZFS requires hostId set
  networking.hostId = "5cdce191";

  swapDevices = [ ];

  fileSystems = {
    "/" = {
      device = "NIX/root";
      fsType = "zfs";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/B503-FC0B";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };
}
