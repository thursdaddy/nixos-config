_: {
  configurations.nixos.aarch64-sd.module =
    { config, pkgs, ... }:
    {
      users.users.${config.mine.base.user.name}.initialPassword = "changeme";

      security.sudo.extraRules = [
        {
          users = [ "${config.mine.base.user.name}" ];
          commands = [
            {
              command = "ALL";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];

      hardware.enableRedistributableFirmware = true;

      security.sudo-rs.enable = true;

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [ "noatime" ];
        };
      };

      networking = {
        hostId = "00000000";
        defaultGateway = "192.168.10.1";
        nameservers = [
          "192.168.10.201"
          "192.168.10.60"
        ];
      };

      boot = {
        initrd.allowMissingModules = true;
        kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
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

      mine = {
        dev.crush.enable = false;
      };
    };
}
