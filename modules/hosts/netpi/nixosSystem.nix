{
  config,
  inputs,
  lib,
  ...
}:
{
  flake = {
    nixosConfigurations.netpi1 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
        hostName = "netpi1";
        hostIp = "192.168.10.57";
        tailscaleIp = "100.87.178.46";
      };
      modules = [
        config.configurations.nixos.netpi.module
      ];
    };

    nixosConfigurations.netpi2 = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit lib;
        hostName = "netpi2";
        hostIp = "192.168.10.201";
        tailscaleIp = "100.106.108.74";
      };
      modules = [
        config.configurations.nixos.netpi.module
      ];
    };
  };
}
