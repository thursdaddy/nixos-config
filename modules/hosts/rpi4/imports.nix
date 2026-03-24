{ config, ... }:
{
  configurations.nixos.rpi4.module = {
    imports = with config.flake.modules.nixos; [
      base
      dev
      services
    ];
  };
}
