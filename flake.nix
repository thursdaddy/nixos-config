{
  description = "It's all coming together..";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
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

  outputs = { self, nixpkgs, nixos-generators, nixvim, nix-darwin, home-manager, hyprland, hyprlock, hyprpaper, unstable, ... }@inputs:
  let
    lib = nixpkgs.lib.extend (self: super: { thurs = import ./lib { inherit inputs; lib = self; }; });
    # used wtih devShells
    supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    });
  in {
    darwinConfigurations = {
      "mbp" = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; inherit lib; };
        system = "aarch64-darwin";
        modules = [
          ./hosts/mbp/configuration.nix
        ];
      };
    };
    nixosConfigurations = {
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
    devShells = forEachSupportedSystem ({ pkgs }: {
      tf = pkgs.mkShell {
        buildInputs = [
          pkgs.opentofu
          pkgs.awscli2
        ];
      };
      kubectl = pkgs.mkShell {
        buildInputs = [
          pkgs.kubectl
          pkgs.awscli2
        ];
      };
      pulumi = pkgs.mkShell {
        buildInputs = [
          pkgs.pulumi-bin
          pkgs.python311
          pkgs.awscli2
        ];
      };
      python = pkgs.mkShell {
        buildInputs = [
          pkgs.python311
        ];
      };
    });
  };
}
