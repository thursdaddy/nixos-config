_: {
  flake.modules.nixos.base =
    { lib, config, ... }:
    let
      cfg = config.mine.base.nfs-mounts;
    in
    {
      options.mine.base.nfs-mounts = {
        enable = lib.mkEnableOption "NFS mounts";
        mounts = lib.mkOption {
          description = "NFS Mount configs";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              freeformType = lib.types.attrs;
              options = {
                device = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "NFS address and path";
                };
                fsType = lib.mkOption {
                  type = lib.types.str;
                  default = "nfs";
                  description = "fsType";
                };
                options = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [
                    "auto"
                    "_netdev"
                    "bg"
                    "timeo=30"
                    "retrans=2"
                    "x-systemd.mount-timeout=10"
                  ];
                  description = "Default mount options";
                };
              };
            }
          );
        };
      };

      config = lib.mkIf cfg.enable {
        fileSystems = lib.mapAttrs' (name: mountConfig: {
          inherit name;
          value = {
            inherit (mountConfig) device;
            inherit (mountConfig) fsType;
            inherit (mountConfig) options;
          };
        }) config.mine.base.nfs-mounts.mounts;
      };
    };
}
