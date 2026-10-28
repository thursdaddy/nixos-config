_: {
  configurations.nixos.tailpi.module =
    { config, pkgs, ... }:
    let
      inherit (config.mine.base) user;
    in
    {
      nixpkgs.hostPlatform = "aarch64-linux";
      system.stateVersion = "24.11";

      boot = {
        initrd = {
          allowMissingModules = true;

          availableKernelModules = [
            "bcmgenet"
            "broadcom"
            "sdhci_iproc"
            "mmc_block"
            "xhci_pci"
            "usbhid"
            "usb_storage"
            "uas"
            "sd_mod"
            "dm_mod"
            "dm_crypt"
            "cryptd"
            "aes_ce_blk"
            "aes_ce_cipher"
            "ghash_ce"
            "sha2_ce"
            "ext4"
            "vfat"
            "nls_cp437"
            "nls_iso8859_1"
          ];

          luks.devices.cryptroot = {
            device = "/dev/disk/by-label/NIXOS_LUKS";
            allowDiscards = true;
          };

          network = {
            enable = true;
            ssh = {
              enable = true;
              port = 2222;
              ignoreEmptyHostKeys = true;
              authorizedKeys = config.users.users.${user.name}.openssh.authorizedKeys.keys;
            };
          };

          systemd = {
            enable = true;
            network = {
              enable = true;
              networks."99-ethernet-default-dhcp".dhcpV4Config.ClientIdentifier = "mac";
            };

            mounts = [
              {
                what = "/dev/disk/by-label/FIRMWARE";
                where = "/boot";
                type = "vfat";
                options = "ro,umask=0077";
                wantedBy = [ "initrd.target" ];
                unitConfig = {
                  DefaultDependencies = false;
                  Conflicts = [
                    "initrd-switch-root.target"
                    "umount.target"
                  ];
                  Before = [
                    "initrd-switch-root.target"
                    "umount.target"
                  ];
                };
              }
            ];

            tmpfiles.settings."50-ssh-host-keys" = {
              "/etc/ssh/ssh_host_ed25519_key"."C" = {
                argument = "/boot/initrd/ssh_host_ed25519_key";
                mode = "0600";
              };
            };

            services.systemd-tmpfiles-setup = {
              before = [ "sshd.service" ];
              unitConfig.RequiresMountsFor = [ "/boot" ];
            };
          };
        };

        kernel.sysctl = {
          "vm.mmap_rnd_bits" = 24;
        };
        kernelPackages = pkgs.rpi4KernelPackages;

        loader = {
          grub.enable = false;
          generic-extlinux-compatible.enable = true;
        };
      };

      systemd.network.networks."99-ethernet-default-dhcp".dhcpV4Config.ClientIdentifier = "mac";

      hardware.enableRedistributableFirmware = true;
      hardware.raspberry-pi.configtxt.deviceTreeOverlays."board-type=0x11" = [
        {
          rpi-poe-plus = { };
        }
      ];

      fileSystems = {
        "/" = {
          device = "/dev/mapper/cryptroot";
          fsType = "ext4";
          options = [ "noatime" ];
        };
        "/boot" = {
          device = "/dev/disk/by-label/FIRMWARE";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
            "noatime"
          ];
        };
      };
    };
}
