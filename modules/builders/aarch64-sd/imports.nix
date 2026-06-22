{ config, ... }:
{
  configurations.nixos.aarch64-sd.module = {
    imports = with config.flake.modules.nixos; [
      base
      dev
    ];
  };
}
