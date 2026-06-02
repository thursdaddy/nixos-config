_: {
  flake.modules.nixos.base =
    { lib, config, ... }:
    let
      hostName = config.networking.hostName;
      cfg = config.mine.homelab.${hostName}.nfs-mounts or { enable = false; mounts = { }; };
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        fileSystems = lib.mapAttrs' (name: mountConfig: {
          inherit name;
          value = {
            inherit (mountConfig) device;
            inherit (mountConfig) fsType;
            inherit (mountConfig) options;
          };
        }) cfg.mounts;
      };
    };
}
