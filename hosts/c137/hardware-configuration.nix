# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "quiet" "splash" "vga=current" "rd.systemd.show_status=false" "rd.udev.log_level=3" "udev.log_priority=3" ];
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;

  boot.initrd.luks.devices = {
    "luks-rpool-nvme-CT2000P5PSSD8_22393B9712C0-part2".device = "/dev/disk/by-id/nvme-CT2000P5PSSD8_22393B9712C0-part2";
  };

  networking.hostId = "c8cf78d0";
  networking.interfaces.enp5s0.wakeOnLan.enable = true;
  networking.interfaces.br0.useDHCP = true;
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp5s0" ];
    };
  };

  fileSystems."/" =
    {
      device = "NIXROOT/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "NIXROOT/home";
      fsType = "zfs";
    };

  fileSystems."/persist" =
    {
      device = "NIXROOT/persist";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/7D91-10AC";
      fsType = "vfat";
    };

  # swapDevices =
  #  [ { device = "/dev/disk/by-uuid/f445a75b-5234-4534-964b-eedb46af1c99"; }
  #   ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp7s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
