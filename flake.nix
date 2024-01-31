{
  description = "I have no idea what I am doing";

  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/release-23.11";
      nixpkgs-unstable.url = "github:nixos/nixpkgs";

      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ...}@inputs: {
      nixosConfigurations = {
          "nixvm-dev" = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
               ./hosts/nixvm-dev/configuration.nix
              ];
          };
          "nixvm" = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
               ./hosts/nixvm/configuration.nix
              ];
          };
      };
  };
}
