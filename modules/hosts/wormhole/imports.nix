{ config, ... }:
{
  configurations.nixos.wormhole.module = {
    imports = with config.flake.modules.nixos; [
      base
      containers
      dev
      services
    ];
  };
}
