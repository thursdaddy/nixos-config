{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.rpi4 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        config.configurations.nixos.rpi4.module
      ];
    };
  };
}
