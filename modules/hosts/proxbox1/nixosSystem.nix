{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.proxbox1 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.proxbox1.module
      ];
    };
  };
}
