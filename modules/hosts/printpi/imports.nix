{ config, inputs, ... }:
{
  configurations.nixos.printpi.module = {
    imports =
      with config.flake.modules.nixos;
      [
        base
        containers
        octoprint
        services
      ]
      ++ [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ];
  };
}
