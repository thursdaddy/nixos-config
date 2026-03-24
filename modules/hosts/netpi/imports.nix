{ config, inputs, ... }:
{
  configurations.nixos.netpi.module = {
    imports =
      with config.flake.modules.nixos;
      [
        base
        blocky
        services
      ]
      ++ [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ];
  };
}
