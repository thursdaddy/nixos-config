{ config, ... }:
{
  configurations.nixos.streambox.module = {
    imports = with config.flake.modules.nixos; [
      base
      containers
      services
    ];
  };
}
