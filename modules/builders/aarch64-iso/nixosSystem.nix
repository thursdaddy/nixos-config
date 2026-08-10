{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.aarch64-iso = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.aarch64-iso.module
      ];
    };
  };
}
