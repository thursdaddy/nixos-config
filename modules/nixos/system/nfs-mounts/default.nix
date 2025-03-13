{ lib, config, ... }:
let
  inherit (lib)
    mkEnableOption
    mapAttrs
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.system.nfs-mounts;

in
{
  options.mine.system.nfs-mounts = {
    enable = mkEnableOption "NFS mounts";
    mounts = mkOption {
      description = "NFS Mount configs";
      default = { };
      type = types.attrsOf (
        lib.types.submodule {
          freeformType = lib.types.attrs;
          options = {
            device = mkOpt (types.nullOr types.str) null "NFS address and path";
            fsType = mkOpt types.str "nfs" "fsType";
            options = mkOpt (types.listOf types.str) [
              "auto"
              "rw"
              "defaults"
              "_netdev"
            ] "Default mount options";
          };
        }
      );
    };
  };

  config = mkIf cfg.enable {
    fileSystems = lib.mapAttrs' (name: mountConfig: {
      name = name;
      value = {
        device = mountConfig.device;
        fsType = mountConfig.fsType;
        options = mountConfig.options;
      };
    }) config.mine.system.nfs-mounts.mounts;
  };
}
