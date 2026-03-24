{ config, inputs, ... }:
{
  configurations.nixos.vm.module = {
    imports =
      with config.flake.modules.nixos;
      [
        base
        dev
        home
        containers
      ];
  };
}
