# Inspired by @ElvishJerricco: https://github.com/ElvishJerricco/stage1-tpm-tailscale/tree/main
{ lib, pkgs, inputs, utils, config, ... }:
let

  tailscale = config.services.tailscale;
  user = config.mine.user;
  zfspool = "${utils.escapeSystemdPath "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S466NX0M752674K-part2"}.device";

in
{
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  config = {
    environment.systemPackages = with pkgs; [
      cryptsetup
      sbctl
      tpm2-tss
    ];

    # Enable Secure Boot, this requires additional steps to fully configure:
    # https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    boot.initrd = {
      kernelModules = [ "tpm_crb" "r8169" ];
      availableKernelModules = [ "ext4" "igb" "tun" "nft_chain_nat" ];
      services = {
        resolved.enable = true;
      };

      # Enable and configure network for SSH connectivity
      network = {
        enable = true;
        ssh = {
          enable = true;
          ignoreEmptyHostKeys = true;
          authorizedKeys = config.users.users.${user.name}.openssh.authorizedKeys.keys;
        };
      };

      # Luks volume with nix root dataset zfs key
      luks.devices.keystore = {
        device = "/dev/disk/by-uuid/a9b17587-91b8-42bd-8029-53487520ffe3";
        crypttabExtraOpts = [ "tpm2-device=auto" "nofail" ];
      };
      # Luks volume containing ssh host keys and tailscale statedir
      luks.devices.tpm2vpn = {
        device = "/dev/disk/by-uuid/fbb1a9a1-f6e2-4d04-b823-1e67bc4d4aba";
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      };

      systemd = {
        enable = true;
        extraBin.ping = "${pkgs.iputils}/bin/ping";
        emergencyAccess = "$6$LqrW7LCddFgpEu5P$YKQFUh96sq2RfB7VSxG041STkM.ZipEaJbC5cGkiCAR6dfQEUcbzqNyAb1Fqu5MHYJPuHSfpxiKcUli.Hff8Z.";
        packages = [ pkgs.tailscale ];
        initrdBin = [ pkgs.iptables pkgs.iproute2 pkgs.tailscale ];
        users.systemd-resolve = { };
        groups.systemd-resolve = { };

        network = {
          enable = true;
          networks."50-tailscale" = {
            matchConfig = {
              Name = tailscale.interfaceName;
            };
            linkConfig = {
              Unmanaged = true;
              ActivationPolicy = "manual";
            };
          };
        };

        # Populate /etc/fstab and ssh host keys
        contents = {
          "/etc/fstab".text = ''
            /dev/mapper/tpm2vpn /tpm2vpn ext4 defaults 0 2
            /tpm2vpn/var/lib/tailscale /var/lib/tailscale none bind,x-systemd.requires-mounts-for=/tpm2vpn/var/lib/tailscale
            # nofail so it doesn't order before local-fs.target and therefore systemd-tmpfiles-setup
            /dev/mapper/keystore /keystore ext4 defaults,nofail,x-systemd.device-timeout=0,ro 0 2
          '';
        };

        tmpfiles.settings."50-tailscale" = {
          "/var/run"."L".argument = "/run";
        };
        tmpfiles.settings."50-ssh-host-keys" = {
          "/etc/ssh/ssh_host_ed25519_key"."C" = {
            argument = "/tpm2vpn/etc/ssh/ssh_host_ed25519_key";
            mode = "0600";
          };
          "/etc/ssh/ssh_host_rsa_key"."C" = {
            argument = "/tpm2vpn/etc/ssh/ssh_host_rsa_key";
            mode = "0600";
          };
        };

        services = {
          # Do not start SSH until the systemd.contents have been created
          systemd-tmpfiles-setup.before = [ "sshd.service" ];
          # Disable NixOS ZFS auto-import root zfs dataset
          zfs-import-NIX.enable = false;

          # Import ZFS pool, but dont load-key until /keystore which is a luks vol requiring password
          import-nixroot-bare = {
            requiredBy = [ "nixroot-load-key.service" ];
            after = [ zfspool ];
            bindsTo = [ zfspool ];
            unitConfig.DefaultDependencies = false;
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${config.boot.zfs.package}/bin/zpool import -f -N -d /dev/disk/by-label NIX";
              RemainAfterExit = true;
            };
          };

          # ZFS load-key after password entered after the command `systemctl default` and /keystore is mounted
          nixroot-load-key = {
            wantedBy = [ "sysroot.mount" ];
            before = [ "sysroot.mount" ];
            unitConfig = {
              RequiresMountsFor = "/keystore";
              DefaultDependencies = false;
            };
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${config.boot.zfs.package}/bin/zfs load-key -L file:///keystore/workbox.key NIX/root";
              RemainAfterExit = true;
            };
          };

          # Enable tailscale and systemd resolved
          tailscaled = {
            wantedBy = [ "initrd.target" ];
            serviceConfig.Environment = [
              "PORT=${toString tailscale.port}"
              ''"FLAGS=--tun ${lib.escapeShellArg tailscale.interfaceName}"''
            ];
          };
        };
      };
    };
  };
}
