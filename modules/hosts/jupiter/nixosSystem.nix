{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.jupiter = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.jupiter.module
      ];
    };
  };
}
