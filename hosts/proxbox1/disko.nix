_: {
  disko.devices = {
    disk = {
      main = {
        # When using disko-install, we will overwrite this value from the commandline
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S466NX0M752674K";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "NIX";
              };
            };
          };
        };
      };
    };
    zpool = {
      NIX = {
        type = "zpool";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          sync = "disabled";
          compression = "lz4";
          mountpoint = "none";
          "com.sun:auto-snapshot" = "false";
        };
        postCreateHook = "zfs snapshot NIX@blank";

        datasets = {
          root = {
            type = "zfs_fs";
            options = {
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
              encryption = "aes-256-gcm";
              keylocation = "prompt";
              keyformat = "passphrase";
            };
            mountpoint = "/";
          };
          keystore = {
            type = "zfs_volume";
            size = "100m";
          };
          tpm2vpn = {
            type = "zfs_volume";
            size = "100m";
          };
        };
      };
    };
  };
}
