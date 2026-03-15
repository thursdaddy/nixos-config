_: {
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.base.bluetooth;
    in
    {
      options.mine.base.bluetooth = {
        enable = lib.mkEnableOption "Enable bluetooth";
      };

      config = lib.mkIf cfg.enable {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            Policy = {
              AutoEnable = true;
            };
            General = {
              Experimental = true;
            };
          };
        };
      };
    };
}
