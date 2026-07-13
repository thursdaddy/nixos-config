{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.gcloudbox = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        (inputs.nixpkgs + "/nixos/modules/virtualisation/google-compute-image.nix")
        config.configurations.nixos.gcloudbox.module
      ];
    };
  };
}
