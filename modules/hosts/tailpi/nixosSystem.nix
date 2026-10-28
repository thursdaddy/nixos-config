{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.tailpi = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
        config.configurations.nixos.tailpi.module
      ];
    };
  };
}
