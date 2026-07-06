{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.ami = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.ami.module
      ];
    };
  };
}
