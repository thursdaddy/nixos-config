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

    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland/1c460e98f870676b15871fe4e5bfeb1a32a3d6d8"; #v0.36.0
    hyprlock.url = "github:hyprwm/Hyprlock";
  };

  outputs = { self, nixpkgs, nixos-generators, nixvim, home-manager, hyprland, hyprlock, ... }@inputs:
  let
    lib = nixpkgs.lib.extend (self: super: { thurs = import ./lib { inherit inputs; lib = self; }; });
  in {
    nixosConfigurations = {
      "nixvm-dev" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; inherit lib; };
        system = "x86_64-linux";
        modules = [
          ./hosts/nixvm-dev/configuration.nix
        ];
      };
      "nixvm" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; inherit lib; };
        system = "x86_64-linux";
        modules = [
          ./hosts/nixvm/configuration.nix
        ];
      };
      "c137" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; inherit lib; };
        system = "x86_64-linux";
        modules = [
          ./hosts/c137/configuration.nix
        ];
      };
    };
    packages.x86_64-linux = {
      iso = nixos-generators.nixosGenerate {
        specialArgs = { inherit inputs; inherit lib; };
        system = "x86_64-linux";
        format = "iso";
        modules = [
          ./systems/x86_64-iso
        ];
      };
    };
  };
}
