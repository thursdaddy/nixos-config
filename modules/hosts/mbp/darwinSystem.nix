{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    darwinConfigurations.mbp = inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.darwin.mbp.module
      ];
    };
  };
}
