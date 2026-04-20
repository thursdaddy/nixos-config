{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.x86_64-iso = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.x86_64-iso.module
      ];
    };
  };
}
