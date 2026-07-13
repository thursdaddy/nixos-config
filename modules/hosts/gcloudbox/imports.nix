{ config, inputs, ... }:
{
  configurations.nixos.gcloudbox.module = {
    imports = with config.flake.modules.nixos; [
      base
      containers
      services
    ];
  };
}
