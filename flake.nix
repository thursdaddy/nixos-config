{
  description = "I have no idea what I am doing";

  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/release-23.11";
      nixpkgs-unstable.url = "github:nixos/nixpkgs";

      home-manager.url = "github:nix-community/home-manager";
      home-manager.inputs.nixpkgs.follows = "nixpkgs";

      nixos-generators = {
          url = "github:nix-community/nixos-generators";
          inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-generators, ...}@inputs:
    let
        username = "thurs";
    in {
      nixosConfigurations = {
          "nixvm-dev" = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit username; };
              system = "x86_64-linux";
              modules = [
               ./hosts/nixvm-dev/configuration.nix
               ./modules/nixos/user
              ];
          };
          "nixvm" = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit username; };
              system = "x86_64-linux";
              modules = [
               ./hosts/nixvm/configuration.nix
               ./modules/nixos/user
              ];
          };
      };
      packages.x86_64-linux = {
          iso = nixos-generators.nixosGenerate {
              specialArgs = { inherit username; };
              system = "x86_64-linux";
              modules = [
                ./systems/x86_64-iso
                ./modules/nixos/user
                ./hosts/shared
              ];
              format = "iso";
          };
      };
  };
}
