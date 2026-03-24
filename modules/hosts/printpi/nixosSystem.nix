{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.printpi = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.printpi.module
      ];
    };
  };
}
