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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "github:thursdaddy/sops-secrets/main";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hyprlock.url = "github:hyprwm/Hyprlock";
    hyprpaper.url = "github:hyprwm/Hyprpaper";
  };

  outputs = { self, nixpkgs, nixos-generators, nixvim, nix-darwin, home-manager, hyprland, hyprlock, hyprpaper, unstable, sops-nix, secrets, ... }@inputs:
    let
      lib = nixpkgs.lib.extend (self: super: { thurs = import ./lib { inherit inputs; lib = self; }; });
      # used wtih devShells
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      });
    in
    {
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
        ami = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          format = "amazon";
          modules = [
            ./systems/x86_64-ami
          ];
        };
        sd-aarch64 = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; };
          system = "aarch64-linux";
          format = "sd-aarch64";
          modules = [
            ./systems/aarch64-sd
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
