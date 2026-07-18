{ config, ... }:
{
  configurations.nixos.streambox.module = {
    imports = with config.flake.modules.nixos; [
      celler
      base
      containers
      services
    ];
  };
}
