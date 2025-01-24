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
      url = "github:LnL7/nix-darwin";
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
      url = "github:nix-community/lanzaboote/v0.3.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, unstable, nixos-hardware, nix-darwin, nixos-generators, home-manager, sops-nix, lanzaboote, nixos-thurs, ssh-keys, nixvim, ... } @ inputs:
    let
      lib = nixpkgs.lib.extend (self: super: { thurs = import ./lib { inherit inputs; lib = self; }; });
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
            inputs.nixos-thurs.nixosModules.c137Containers
          ];
        };
        "cloudbox" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          modules = [
            ./hosts/cloudbox/configuration.nix
            inputs.nixos-thurs.nixosModules.cloudboxContainers
          ];
        };
        "workbox" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          modules = [
            ./hosts/workbox/configuration.nix
            inputs.nixos-thurs.nixosModules.workboxContainers
          ];
        };
        "netpi1" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; hostname = "netpi1"; };
          system = "aarch64-linux";
          modules = [
            ./hosts/netpi/configuration.nix
            inputs.nixos-thurs.nixosModules.netpiContainers
          ];
        };
        "netpi2" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; hostname = "netpi2"; };
          system = "aarch64-linux";
          modules = [
            ./hosts/netpi/configuration.nix
            inputs.nixos-thurs.nixosModules.netpiContainers
          ];
        };
        "printpi" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          system = "aarch64-linux";
          modules = [
            ./hosts/printpi/configuration.nix
            inputs.nixos-thurs.nixosModules.printpiContainers
          ];
        };
      };

      packages = forEachSupportedSystem ({ pkgs }: {
        upSnap = pkgs.callPackage ./packages/upsnap.nix { inherit unstable; };
        wallpapers = pkgs.stdenv.mkDerivation {
          name = "wallpapers";
          src = ./.;
          installPhase = ''
            mkdir -p $out/
            cp -Rf ./assets/wallpapers/ $out/
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
          ];
        };
      });

      devShells = forEachSupportedSystem ({ pkgs }: {
        tf = pkgs.mkShell {
          buildInputs = [
            pkgs.opentofu
            pkgs.awscli2
          ];
        };
        python = pkgs.mkShell {
          buildInputs = [
            pkgs.python312Full
            (pkgs.python312.withPackages (ps: with ps; with pkgs.python312Packages; [
              requests
            ]))
          ];
        };
      });
    };
}
