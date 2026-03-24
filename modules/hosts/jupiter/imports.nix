{ config, ... }:
{
  configurations.nixos.jupiter.module = {
    imports = with config.flake.modules.nixos; [
      base
      containers
      services
    ];
  };
}
