NixOS
=====

My always evolving Nix flake ❄

Est. Feb 2024

## Flake Inputs

| Name | Details |
|:-----------| :------|
| [nixpkgs](https://github.com/NixOS/nixpkgs/tree/nixos-24.11) | 24.11 |
| [unstable](https://github.com/NixOS/nixos-unstable) | Unstable nixpkgs |
| [nixos-thurs](github:thursdaddy/nixos-thurs/main) | Private repo with sops secrets and docker container configurations via nixosModules |
| [home-manager](https://github.com/nix-community/home-manager/tree/release-24.11) | Manage apps and configs via nix! Importing as NixOS and Darwin modules (Not standalone) |
| [lanzaboote](https://github.com/nix-community/lanzaboote) | Wallpaper manager for Hyprland configured via home-manager|
| [nix-darwin](https://github.com/LnL7/nix-darwin) | Nix on MacOS |
| [nix-index-database](https://github.com/nix-community/nix-index-database) | Nix on MacOS |
| [nixos-generators](https://github.com/nix-community/nixos-generators) | Create NixOS configurations for various targets |
| [nixvim](https://github.com/nix-community/nixvim/tree/main) | Fully configurable Neovim, imported via NixOS and Darwin modules |
| [ssh-keys](https://github.com/thursdaddy.keys) | SSH Pub Keys from GitHub|
| [sops](https://github.com/Mic92/sops-nix) | Nix sops implementation|


## Structure

```
├── assets/          # wallpapers, misc
├── hosts/
    ├── c137/        # AMD 5950x, 64GB DDR4, AMD 6600XT
    ├── cloudbox/    # AWS instance
    ├── homebox/     # Lenovo ThinkCentre M700, i5-6500T, 16GB DDR4
    ├── mbp/         # 2021 MBP M1
    ├── netpi/       # Pi4's running pihole + tailscale
    ├── printpi/     # Pi4 running octoprint
    ├── proxbox/     # AMD 5900HX, 32GB DDR4
    ├── jupiter/     # VM for self-hosted apps
    ├── kepler/      # VM for monitoring tools
    ├── wormhole/    # VM for general use
├── flake.nix
├── flake.lock
├── lib/             # extending lib with my own functions
├── modules/
    ├── darwin/      # darwin configurations
    ├── home/        # home-manager configurations
    ├── nixos/       # nixos configurations
    ├── nixvim/      # nixvim configurations
    ├── shared/      # shared darwin and nixos configurations
├── overlays/        # overlay configurations
├── packages/        # personal packages
└── systems/         # nixos-generator targets
└── build            # utility build script (im lazy)
```

## Notes

All modules are imported on a per system basis via the hosts `configuration.nix` file and individually enabled via module system.

 - darwin       -> `modules/darwin/import.nix`
 - home-manager -> `modules/home/import.nix`
 - nixos        -> `modules/nixos/import.nix`
 - nixvim       -> `modules/nixvim/import.nix`
 - shared       -> `modules/shared/import.nix`
