{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.streambox = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.streambox.module
      ];
    };
  };
}
