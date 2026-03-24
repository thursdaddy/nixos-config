{ config, ... }:
{
  configurations.nixos.kepler.module = {
    imports = with config.flake.modules.nixos; [
      base
      containers
      services
    ];
  };
}
