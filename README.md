My NixOS configuration
======================

Here is my always evolving Nix flake ❄

Est, Feb 2024.

## Flake Inputs

| Name | Details |
|:-----------| :------|
| [nixpkgs](https://github.com/NixOS/nixpkgs/tree/nixos-23.11) | 23.11 |
| [nix-darwin](https://github.com/LnL7/nix-darwin) | Nix on MacOS |
| [home-manager](https://github.com/nix-community/home-manager/tree/release-23.11) | Manage apps and configs via nix! Importing as NixOS and Darwin modules (Not standalone) |
| [nixos-generators](https://github.com/nix-community/nixos-generators) | Create NixOS configurations for various targets |
| [NixVim](https://github.com/nix-community/nixvim/tree/nixos-23.11) | Fully configurable Neovim, imported via NixOS and Darwin modules |
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
├── flake.nix
├── flake.lock
├── lib             # extending lib with my own functions
├── modules
    ├── darwin      # darwin configurations
    ├── home        # home-manager configurations
    ├── nixos       # nixos configurations
├── shells          # flakes for direnv devShells
└── systems         # nixos-generator targets
```

## Notes

The end goal was to easily enable/disable module configurations via custom boolean options, for example `mine.cli-apps.nixvim = enabled`. All module configurations are disabled by default.

This requires an opinionated repo structure and naming convention. All modules are in defined via directory name that contains a `default.nix` file, and their custom options should be system/arch agnostic.

> You could argue there is an excessive use of directory separation but bulk importing, covered below, makes this a lot easier.

All modules are imported per system basis via the hosts `configuration.nix` file.

 - Darwin       -> `modules/darwin/import.nix`
 - home-manager -> `modules/home/import.nix`
 - NixOS        -> `modules/nixos/import.nix`
 - NixVim       -> `modules/nixos/cli-apps/nixvim/import.nix` (see note below)

A few enefits I see are being able to easily re-use existing files as templates for a new configuration or
if I want to entirely disable a module I can simply rename it to `default.nix.disabled`. It also allows me to easily navigate the folder structure using neovim and fzf to find a specific module.

> NixVim Note: The nixvim files are `nix.vim` to allow them to be imported along with NixVims nixos
and darwin modules. Works well for now but may be re-architected in the future.
