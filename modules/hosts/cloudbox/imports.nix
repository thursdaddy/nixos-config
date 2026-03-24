{ config, inputs, ... }:
{
  configurations.nixos.cloudbox.module = {
    imports = with config.flake.modules.nixos; [
      base
      containers
      services
    ];
  };
}
