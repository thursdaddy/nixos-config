{
  description = "I have no idea what I am doing";

  inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

      home-manager = {
          url = "github:nix-community/home-manager/release-23.11";
          inputs.nixpkgs.follows = "nixpkgs";
      };

      nixos-generators = {
          url = "github:nix-community/nixos-generators";
          inputs.nixpkgs.follows = "nixpkgs";
      };
  };

  outputs = { self, nixpkgs, nixos-generators, home-manager, ... }@inputs:
    let
        username = "thurs";
    in {
      nixosConfigurations = {
          "nixvm-dev" = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit username; inherit inputs; };
              system = "x86_64-linux";
              modules = [
               ./hosts/nixvm-dev/configuration.nix
               home-manager.nixosModules.home-manager
               {
                   home-manager.useGlobalPkgs = true;
                   home-manager.extraSpecialArgs = { inherit username; inherit inputs; }; # allows access to flake inputs in hm modules
                   home-manager.users.${username}.imports = [ ./hosts/nixvm-dev/home.nix ];
               }
              ];
          };
          "nixvm" = nixpkgs.lib.nixosSystem {
              specialArgs = { inherit username; };
              system = "x86_64-linux";
              modules = [
               ./hosts/nixvm/configuration.nix
              ];
          };
      };
      packages.x86_64-linux = {
          iso = nixos-generators.nixosGenerate {
              specialArgs = { inherit username; };
              system = "x86_64-linux";
              modules = [
                ./systems/x86_64-iso
                ./hosts/shared
                ./modules/nixos/programs/zsh
                ./modules/nixos/user
              ];
              format = "iso";
          };
      };
  };
}
