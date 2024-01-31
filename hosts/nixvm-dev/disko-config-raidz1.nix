{
  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "2G";
              type = "EF00";
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
                pool = "NIXROOT";
              };
            };
          };
        };
      };
      sdb = {
       type = "disk";
       device = "/dev/sdb";
       content = {
         type = "zfs";
         pool = "NIXROOT";
       };
      };
      sdc = {
       type = "disk";
       device = "/dev/sdc";
       content = {
         type = "zfs";
         pool = "NIXROOT";
       };
      };
      sdd = {
       type = "disk";
       device = "/dev/sdd";
       content = {
         type = "zfs";
         pool = "NIXROOT";
       };
     };
    };
    zpool = {
      NIXROOT = {
        mode = "raidz";
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
          encryption = "aes-256-gcm";
          keylocation = "prompt";
          keyformat = "passphrase";
          compression = "lz4";
          mountpoint = "none";
          "com.sun:auto-snapshot" = "false";
        };
        postCreateHook = "zfs snapshot NIXROOT@blank";

        datasets = {
          root = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            options."com.sun:auto-snapshot" = "true";
          };
          home  = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/home";
          };
          persist  = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
          };
        };
      };
    };
  };
}


