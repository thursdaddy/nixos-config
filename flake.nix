{
  description = "I have no idea what I am doing";

  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

      nixos-generators = {
          url = "github:nix-community/nixos-generators";
          inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = { self, nixpkgs, nixos-generators, ...}@inputs:
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
