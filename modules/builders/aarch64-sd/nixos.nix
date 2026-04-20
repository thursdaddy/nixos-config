{
  config,
  inputs,
  ...
}:
{
  flake = {
    nixosConfigurations.aarch64-sd = inputs.nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        config.configurations.nixos.aarch64-sd.module
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ];
    };
  };
}
