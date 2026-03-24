{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.cloudbox = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        (inputs.nixpkgs + "/nixos/modules/virtualisation/amazon-image.nix")
        config.configurations.nixos.cloudbox.module
      ];
    };
  };
}
