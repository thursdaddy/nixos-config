{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.gce = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.gce.module
      ];
    };
  };
}
