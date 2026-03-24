{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.homebox = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.homebox.module
      ];
    };
  };
}
