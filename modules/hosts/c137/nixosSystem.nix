{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.c137 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.c137.module
      ];
    };
  };
}
