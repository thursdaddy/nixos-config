{ config, ... }:
{
  configurations.nixos.aarch64-sd.module = {
    imports = with config.flake.modules.generic; [
      base
      dev
    ];
  };
}
