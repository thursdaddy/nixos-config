{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
      };
      modules = [
        config.configurations.nixos.vm.module
        (
          { config, modulesPath, ... }:
          {
            imports = [
              "${modulesPath}/virtualisation/qemu-vm.nix"
            ];
            nixpkgs.hostPlatform = "x86_64-linux";
            system.stateVersion = "24.11";
          }
        )
      ];
    };
  };
}
