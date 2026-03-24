_: {
  flake.modules.nixos.services =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.mine.services.prometheus;
      name = "prometheus";
    in
    {
      options.mine.services.${name} = {
        exporters = lib.mkOption {
          default = { };
          type = lib.types.submodule {
            options = {
              node.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable node exporter";
              };
              smartctl.enable = lib.mkEnableOption "Enable smartctl exporter";
              zfs.enable = lib.mkEnableOption "Enable ZFS exporter";
            };
          };
        };
      };

      config = {
        services.prometheus = {
          exporters = {
            node = lib.mkIf cfg.exporters.node.enable {
              enable = true;
              enabledCollectors = [ "systemd" ];
              openFirewall = true;
            };
            smartctl = lib.mkIf cfg.exporters.smartctl.enable {
              enable = true;
              openFirewall = true;
            };
            zfs = lib.mkIf cfg.exporters.zfs.enable {
              enable = true;
              openFirewall = true;
            };

          };
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
