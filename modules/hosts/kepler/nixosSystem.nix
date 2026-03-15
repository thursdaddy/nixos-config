{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.kepler = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.kepler.module
      ];
    };
  };
}
