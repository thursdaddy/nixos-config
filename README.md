NixOS
=====

Here is my always evolving Nix flake ❄

Est, Feb 2024.

## Flake Inputs

| Name | Details |
|:-----------| :------|
| [nixpkgs](https://github.com/NixOS/nixpkgs/tree/nixos-23.11) | 23.11 |
| [unstable](https://github.com/NixOS/nixos-unstable) | Unstable |
| [nix-darwin](https://github.com/LnL7/nix-darwin) | Nix on MacOS |
| [home-manager](https://github.com/nix-community/home-manager/tree/release-23.11) | Manage apps and configs via nix! Importing as NixOS and Darwin modules (Not standalone) |
| [nixos-generators](https://github.com/nix-community/nixos-generators) | Create NixOS configurations for various targets |
| [NixVim](https://github.com/nix-community/nixvim/tree/nixos-23.11) | Fully configurable Neovim, imported via NixOS and Darwin modules |
| [sops](https://github.com/Mic92/sops-nix) | Nix sops implementation|
| [nixos-thurs](github:thursdaddy/nixos-thurs/main) | Private repo with config and sops secrets|
| [hyprland](https://github.com/hyprwm/Hyprland) | Wayland tiling WM configured via home-manager|
| [hyprlock](https://github.com/hyprwm/Hyprlock) | Lock screen for Hyprland configured via home-manager|
| [hyprpaper](https://github.com/hyprwm/Hyprpaper) | Wallpaper manager for Hyprland configured via home-manager|


## Structure

```
.
├── assets          # wallpapers, misc
├── hosts
    ├── mbp         # 2021 MBP M1
    ├── c137        # AMD 5950x, 64GB DDR4, AMD 6600XT
    ├── cloudbox    # AWS instance
├── flake.nix
├── flake.lock
├── lib             # extending lib with my own functions
├── modules
    ├── darwin      # darwin configurations
    ├── home        # home-manager configurations
    ├── nixos       # nixos configurations
    ├── nixvim      # nixvim configurations
├── secrets         # encrypted secrets repo
└── systems         # nixos-generator targets
```

## Notes

All modules are imported on a per system basis via the hosts `configuration.nix` file.

 - Darwin       -> `modules/darwin/import.nix`
 - home-manager -> `modules/home/import.nix`
 - NixOS        -> `modules/nixos/import.nix`
 - NixVim       -> `modules/nixvim/import.nix`
