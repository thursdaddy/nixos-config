{ config, ... }:
{
  configurations.nixos.vm.module = {
    imports = with config.flake.modules.nixos; [
      base
      dev
      containers
    ];
  };
}
