{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.wormhole = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.wormhole.module
      ];
    };
  };
}
