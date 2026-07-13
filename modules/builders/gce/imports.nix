{ config, ... }:
{
  configurations.nixos.gce.module = {
    imports = with config.flake.modules.nixos; [
      base
      services
    ];
  };
}
