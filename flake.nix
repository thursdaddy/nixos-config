{
  description = "It's all coming together..";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # private nixos configs
    nixos-thurs = {
      url = "github:thursdaddy/nixos-thurs/main";
    };

    ssh-keys = {
      url = "https://github.com/thursdaddy.keys";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, unstable, nixos-hardware, nix-darwin, nixos-generators, nix-index-database, home-manager, sops-nix, lanzaboote, nixos-thurs, ssh-keys, nixvim, ... } @ inputs:
    let
      lib = nixpkgs.lib.extend (self: super: { thurs = import ./lib { inherit inputs; lib = self; }; });
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      darwinConfigurations = {
        "mbp" = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit inputs; inherit lib; };
          modules = [
            ./hosts/mbp/configuration.nix
            nix-index-database.darwinModules.nix-index
          ];
        };
      };
      nixosConfigurations = {
        "c137" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          modules = [
            ./hosts/c137/configuration.nix
            # inputs.nixos-thurs.nixosModules.c137Containers
            nix-index-database.nixosModules.nix-index
          ];
        };
        "cloudbox" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          modules = [
            ./hosts/cloudbox/configuration.nix
            inputs.nixos-thurs.nixosModules.cloudboxContainers
          ];
        };
        "homebox" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          modules = [
            ./hosts/homebox/configuration.nix
          ];
        };
        "workbox" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          modules = [
            ./hosts/workbox/configuration.nix
            inputs.nixos-thurs.nixosModules.workboxContainers
            nix-index-database.nixosModules.nix-index
          ];
        };
        "netpi1" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; hostname = "netpi1"; };
          modules = [
            ./hosts/netpi/configuration.nix
          ];
        };
        "netpi2" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; hostname = "netpi2"; };
          modules = [
            ./hosts/netpi/configuration.nix
          ];
        };
        "printpi" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          modules = [
            ./hosts/printpi/configuration.nix
            inputs.nixos-thurs.nixosModules.printpiContainers
          ];
        };
      };

      packages = forEachSupportedSystem ({ pkgs }: {
        upSnap = pkgs.callPackage ./packages/upsnap.nix { };
        wallpapers = pkgs.stdenv.mkDerivation {
          name = "wallpapers";
          src = ./assets/wallpapers;
          installPhase = ''
            mkdir -p $out/
            cp -Rf ./ $out/
          '';
        };
        ami = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          format = "amazon";
          modules = [
            ./systems/x86_64-ami
          ];
        };
        iso = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          format = "iso";
          modules = [
            ./systems/x86_64-iso
          ];
        };
        sd-aarch64 = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; inherit lib; };
          system = "aarch64-linux";
          format = "sd-aarch64";
          modules = [
            ./systems/aarch64-sd
          ];
        };
        vm-nogui = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          format = "vm-nogui";
          modules = [
            ./systems/x86_64-vm-nogui
            nix-index-database.nixosModules.nix-index
          ];
        };
      });

      devShells = forEachSupportedSystem ({ pkgs }: {
        tf = with pkgs; mkShell {
          buildInputs = [
            opentofu
            awscli2
          ];
        };
        python = with pkgs; mkShell {
          buildInputs = [
            python312Full
            (python312.withPackages (ps: with ps; with python312Packages; [
              requests
            ]))
          ];
        };
      });
    };
}
