{
  description = "It's all coming together..";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # private nixos configs
    nixos-thurs = {
      # url = "github:thursdaddy/nixos-thurs/main";
      url = "git+file:///home/thurs/projects/nix/nixos-thurs/";
      # url = "git+file:///Users/thurs/projects/nix/nixos-thurs/";
    };

    ssh-keys = {
      url = "https://github.com/thursdaddy.keys";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.11";
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

    hyprland.url = "github:hyprwm/Hyprland/?ref=v0.40.0";
    hyprlock.url = "github:hyprwm/Hyprlock/?ref=v0.3.0";
    hyprpaper.url = "github:hyprwm/Hyprpaper/?ref=v0.7.0";
    hypridle.url = "github:hyprwm/Hypridle/?ref=v0.1.2";
  };

  outputs = { self, nixpkgs, unstable, nix-darwin, nixos-generators, home-manager, sops-nix, nixos-thurs, ssh-keys, nixvim, hyprland, hypridle, hyprlock, hyprpaper, ... } @ inputs:
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
            (import ./overlays/unstable)
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
      nixosConfigurations = {
        "cloudbox" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          modules = [
            ./hosts/cloudbox/configuration.nix
          ];
        };
      };
      nixosConfigurations = {
        "netpi1" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; hostname = "netpi1"; };
          system = "aarch64-linux";
          modules = [
            ./hosts/netpi/configuration.nix
          ];
        };
      };
      nixosConfigurations = {
        "netpi2" = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; inherit lib; hostname = "netpi2"; };
          system = "aarch64-linux";
          modules = [
            ./hosts/netpi/configuration.nix
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
        vm-nogui = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          format = "vm-nogui";
          modules = [
            ./systems/x86_64-vm-nogui
          ];
        };
        ami = nixos-generators.nixosGenerate {
          specialArgs = { inherit inputs; inherit lib; };
          system = "x86_64-linux";
          format = "amazon";
          modules = [
            ./systems/x86_64-ami
            ({ ... }: { amazonImage.sizeMB = 4 * 1024; })
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
        python = pkgs.mkShell {
          buildInputs = [
            pkgs.python311
          ];
        };
      });
    };
}
