{ config, ... }:
{
  configurations.nixos.x86_64-iso.module = {
    imports = with config.flake.modules.nixos; [
      base
    ];
  };
}
