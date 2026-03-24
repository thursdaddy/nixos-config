{ config, ... }:
{
  configurations.nixos.proxbox1.module = {
    imports = with config.flake.modules.nixos; [
      base
      services
    ];
  };
}
