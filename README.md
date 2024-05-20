NixOS
=====

My always evolving Nix flake ❄

Est. Feb 2024

## Flake Inputs

| Name | Details |
|:-----------| :------|
| [nixpkgs](https://github.com/NixOS/nixpkgs/tree/nixos-23.11) | 23.11 |
| [unstable](https://github.com/NixOS/nixos-unstable) | Unstable |
| [home-manager](https://github.com/nix-community/home-manager/tree/release-23.11) | Manage apps and configs via nix! Importing as NixOS and Darwin modules (Not standalone) |
| [nix-darwin](https://github.com/LnL7/nix-darwin) | Nix on MacOS |
| [nixos-generators](https://github.com/nix-community/nixos-generators) | Create NixOS configurations for various targets |
| [nixvim](https://github.com/nix-community/nixvim/tree/nixos-23.11) | Fully configurable Neovim, imported via NixOS and Darwin modules |
| [sops](https://github.com/Mic92/sops-nix) | Nix sops implementation|
| [nixos-thurs](github:thursdaddy/nixos-thurs/main) | Private repo with sops secrets and docker container configurations via nixosModules |
| [hyprland](https://github.com/hyprwm/Hyprland) | Wayland tiling WM configured via home-manager|
| [hyprlock](https://github.com/hyprwm/Hyprlock) | Lock screen for Hyprland configured via home-manager|
| [hyprpaper](https://github.com/hyprwm/Hyprpaper) | Wallpaper manager for Hyprland configured via home-manager|
| [hypridle](https://github.com/hyprwm/Hypridle) | Hyprland's idle daemon configured via home-manager|


## Structure

```
├── assets/          # wallpapers, misc
├── hosts/
    ├── mbp/         # 2021 MBP M1
    ├── c137/        # AMD 5950x, 64GB DDR4, AMD 6600XT
    ├── cloudbox/    # AWS instance
    ├── netpi/       # Pi4's running pihole + tailscale
├── flake.nix
├── flake.lock
├── lib/             # extending lib with my own functions
├── modules/
    ├── darwin/      # darwin configurations
    ├── home/        # home-manager configurations
    ├── nixos/       # nixos configurations
    ├── nixvim/      # nixvim configurations
├── overlays/        # overlay configurations
└── systems/         # nixos-generator targets
└── build            # utility build script (im lazy)
```

## Notes

All modules are imported on a per system basis via the hosts `configuration.nix` file and individually enabled via module system.

 - darwin       -> `modules/darwin/import.nix`
 - home-manager -> `modules/home/import.nix`
 - nixos        -> `modules/nixos/import.nix`
 - nixvim       -> `modules/nixvim/import.nix`
