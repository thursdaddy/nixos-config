{
  config,
  inputs,
  ...
}:
{
  flake = {
    nixosConfigurations.vm = inputs.nixpkgs.lib.nixosSystem {
      modules = [
        config.configurations.nixos.vm.module
        (
          { config, ... }:
          {
            nixpkgs.hostPlatform = "x86_64-linux";
            system.stateVersion = "24.11";
          }
        )
      ];
    };
  };
}
