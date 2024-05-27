{ utils, pkgs, inputs, config, ... }:
{
  boot.initrd = {
    systemd.services.zfs-import-NIX.enable = false; # Disable NixOS ZFS support

    systemd.services.import-nixroot-bare =
      let
        nvme = "${utils.escapeSystemdPath "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_500GB_S466NX0M752674K-part2"}.device";
      in
      {
        requiredBy = [ "nixroot-load-key.service" ];
        after = [ nvme ];
        bindsTo = [ nvme ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.boot.zfs.package}/bin/zpool import -f -N -d /dev/disk/by-label NIX";
          RemainAfterExit = true;
        };
      };

    systemd.services.nixroot-load-key = {
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
  };
}
