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

    hyprland.url = "github:hyprwm/Hyprland";
    hyprlock.url = "github:hyprwm/Hyprlock";
    hyprpaper.url = "github:hyprwm/Hyprpaper";
  };

  outputs = { self, nixpkgs, nixos-generators, nixvim, home-manager, hyprland, hyprlock, hyprpaper, ... }@inputs:
  let
    lib = nixpkgs.lib.extend (self: super: { thurs = import ./lib { inherit inputs; lib = self; }; });
  in {
    devShells.tofu = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = [
        nixpkgs.legacyPackages.x86_64-linux.opentofu
        nixpkgs.legacyPackages.x86_64-linux.awscli2
      ];
    };
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
