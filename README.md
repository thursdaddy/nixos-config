My NixOS configuration
======================

Here is my always evolving Nix flake ❄

Est, Feb 2024.

## Flake Inputs

| Name | Details |
|:-----| :------|
| nixpkgs | 23.11 |
| nix-darwin | Nix on MacOS |
| home-manager | Manage apps and configs via nix! Importing as NixOS and Darwin modules (Not standalone) |
| nixos-genertaors | Create NixOS configurations for various targets |
| NixVim | Fully configurable Neovim, imported via NixOS and Darwin modules |
| hyprland | Wayland tiling WM configured via home-manager|
| hyprlock | Lock screen for Hyprland configured via home-manager|
| hyprpaper | Wallpaper manager for Hyprland configured via home-manager|

## Structure

```
.
├── assets     # wallpapers, misc
├── hosts
    ├── mbp    # 2021 MBP M1
    ├── c137   # 5950x, 64GB DDR4, AMD 6600XT
├── flake.nix
├── flake.lock
├── lib        # extending lib with my own functions
├── modules
    ├── darwin # darwin configurations
    ├── home   # home-manager configurations
    ├── nixos  # nixos configurations
├── shells     # flakes for direnv devShells
└── systems    # nixos-generator targets
```

## Notes

The end goal was to easily define configuration/apps/etc by enabling configurations via
boolean options, ie "mine.cli-app.nixvim = enabled".

This requires an opinionated configuration as far as folder structure and naming conventions go, all
configurations filenames must be `default.nix`.

You could argue there is an excessive use of directory separation but bulk importing, covered below,
makes this a lot easier.

All configurations are imported per system via the hosts `configuration.nix` file.

 - Darwin       -> `modules/darwin/import.nix`
 - home-manager -> `modules/home/import.nix`
 - NixOS        -> `modules/nixos/import.nix`
 - NixVim       -> `modules/nixos/cli-apps/nixvim/import.nix` # see note below

A few enefits I see are being able to easily re-use existing files as templates for a new configuration or
if I want to entirely disable a module I can simply rename it to `default.nix.disabled`.

> ** NixVim Note:_** The nixvim files are `nix.vim` to allow me them to be imported by both the nixos
and the darwin module. Works well for now but may be re-architected in the future.

