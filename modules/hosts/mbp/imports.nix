{ config, ... }:
{
  configurations.darwin.mbp.module = {
    imports = with config.flake.modules.darwin; [
      apps
      base
      desktop
      dev
    ];
  };
}
