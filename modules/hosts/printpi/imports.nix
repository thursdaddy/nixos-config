{ config, inputs, ... }:
{
  configurations.nixos.printpi.module = {
    imports =
      with config.flake.modules.nixos;
      [
        base
        services
        octoprint
      ]
      ++ [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ];
  };
}
