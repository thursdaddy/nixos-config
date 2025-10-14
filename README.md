# NixOS Configuration

My always evolving Nix flake ❄️ for declarative system and user environment management across multiple machines.

Est. Feb 2024

## Flake Inputs

| Name | Details |
|:-----------| :------|
| [nixpkgs](https://github.com/NixOS/nixpkgs/tree/nixos-25.05) | Primary Nix package collection (25.05 release) |
| [unstable](https://github.com/NixOS/nixpkgs/tree/nixos-unstable) | Unstable Nixpkgs for newer packages |
| nixos-thurs | Private repository for sops secrets and Docker container configurations |
| [home-manager](https://github.com/nix-community/home-manager/tree/release-25.05) | Declarative management of user environments (imported as NixOS and Darwin modules) |
| [lanzaboote](https://github.com/nix-community/lanzaboote) | Unified EFI bootloader for NixOS (used in specific hosts) |
| [nix-darwin](https://github.com/LnL7/nix-darwin) | System configuration for macOS using Nix |
| [nix-index-database](https://github.com/nix-community/nix-index-database) | Database for `nix-index` for faster command discovery |
| [nixos-generators](https://github.com/nix-community/nixos-generators) | Tool for generating NixOS system images for various platforms (AMI, ISO, VM, SD) |
| [nixvim](https://github.com/nix-community/nixvim/tree/main) | Declarative Neovim configuration framework |
| [ssh-keys](https://github.com/thursdaddy.keys) | Fetches public SSH keys from GitHub |
| [sops-nix](https://github.com/Mic92/sops-nix) | Nix integration for SOPS (Secrets OPerationS) for managing encrypted secrets |


## Modules

This repository is organized into several module categories. Modules are imported on a per-system basis in each host's `configuration.nix` and can be enabled individually.

-   **[NixOS Modules](https://github.com/thursdaddy/nixos-config/tree/main/modules/nixos):** System-level configurations specific to NixOS.
-   **[Home Manager Modules](https://github.com/thursdaddy/nixos-config/tree/main/modules/home):** User-level configurations managed by Home Manager.
-   **[Darwin Modules](https://github.com/thursdaddy/nixos-config/tree/main/modules/darwin):** System-level configurations specific to macOS (via nix-darwin).
-   **[NixVim Modules](https://github.com/thursdaddy/nixos-config/tree/main/modules/nixvim):** Declarative Neovim configuration.
-   **[Shared Modules](https://github.com/thursdaddy/nixos-config/tree/main/modules/shared):** Configurations that are common across both NixOS and Darwin systems.
-   **[Custom Packages](https://github.com/thursdaddy/nixos-config/tree/main/packages):** Locally defined Nix packages.
-   **[Build Targets](https://github.com/thursdaddy/nixos-config/tree/main/systems):** NixOS configurations for various deployment targets (AMI, ISO, SD card, VM).


Each module set has an `import.nix` file within its root directory to recursively find and import all `default.nix` files beneath it. The import files are declared in the hosts `configuration.nix` `imports` section.

All modules are disabled by default and can be enabled using options, like `services.atticd.enable = true;`.

## Structure

```
├── assets/          # Wallpapers and other miscellaneous assets
├── hosts/
│   ├── c137/        # Main desktop configuration (AMD 5950x, 64GB DDR4, AMD 6600XT)
│   ├── cloudbox/    # AWS instance configuration
│   ├── homebox/     # home server configuration (Lenovo ThinkCentre M700, i5-6500T, 16GB DDR4)
│   ├── mbp/         # Darwin (M1 MacBookPro) configuration
│   ├── netpi/       # RaspPi4 configurations (e.g., for pi-hole + Tailscale)
│   ├── printpi/     # RaspPi4 configuration for Octoprint
│   ├── proxbox1/    # Proxmox VE host configuration
│   ├── jupiter/     # VM configuration for self-hosted apps
│   ├── kepler/      # VM configuration for monitoring tools
│   └── wormhole/    # VM configuration for general use
├── flake.nix
├── flake.lock
├── nix.sh           # Wrapper script for misc operations
├── justfile         # Task runner for nix.sh (build, rebuild, lint, update)
├── lib/             # Custom Nix library functions (extending `nixpkgs.lib`)
├── modules/
│   ├── darwin/      # macOS-specific configurations (applications, system settings, CLI tools)
│   ├── home/        # Home Manager configurations (user-level apps, desktop environments, CLI tools)
│   ├── nixos/       # NixOS-specific configurations (applications, desktop, services, system settings)
│   ├── nixvim/      # NixVim plugin and option configurations
│   └── shared/      # Configurations shared between NixOS and macOS systems (aliases, fonts, CLI tools)
├── overlays/        # Nixpkgs overlays for custom package versions or modifications
├── packages/        # Custom Nix packages defined within this repository
└── systems/         # Definitions for `nixos-generators` targets (AMI, ISO, SD, VM)
```

## Notes


## Building and Deploying

This repository uses a `justfile` and a wrapper script, [`nix.sh`](nix.sh), to simplify common Nix operations.

### `nix.sh` Functions and `just` Commands

#### Rebuilding a System (`rebuild` function)

The `rebuild` function applies the Nix configuration to a target system. It detects if the target is a local machine (NixOS or Darwin) or a remote NixOS host and uses the appropriate rebuild command (`nixos-rebuild switch` or `darwin-rebuild switch`).

| Just Command | Description |
| :--- | :--- |
| `just rebuild` | Rebuilds the configuration for the current host. |
| `just <hostname>` | Rebuilds the configuration for a specific host (e.g., `just c137`, `just mbp`). |

#### Building an Artifact (`build` function)

The `build` function builds a Nix derivation from `flake.nix` without applying it. This is used to create system images such as ISOs, virtual machine disks, or AMIs. The script copies the final artifact into the `builds/` directory.

| Just Command | Description |
| :--- | :--- |
| `just build <target>` | Builds a target such as `vm-nogui`, `iso`, or `ami`. |

#### Managing Flake Inputs (`update_flake_input` & `update_to_local_input` functions)

These functions manage the dependencies (inputs) defined in `flake.nix`. They can update inputs from their remote sources or switch them to a local path for development.

| Just Command | Description |
| :--- | :--- |
| `just update <input>` | Updates a specific flake input (e.g., `just update nixpkgs`). |
| `just update all` | Updates all flake inputs in `flake.lock`. |
| `just local <input>` | Switches an input's URL to a local filesystem path for development (e.g., `just local nixos-thurs`). |

#### Pushing to a Binary Cache (`attic` function)

The `attic` function builds the system derivation for one or all hosts and pushes the resulting paths to an [Attic](https://github.com/zhaofengli/attic) binary cache. This allows other machines to download pre-built packages instead of building them from source.

| Just Command | Description |
| :--- | :--- |
| `just attic <hostname>` | Builds and pushes the derivation for a specific host to the cache. |
| `just attic all` | Builds and pushes derivations for all defined hosts to the cache. |

#### Linting (`statix`)

The `justfile` includes a command for checking the style and syntax of your Nix code.

| Just Command | Description |
| :--- | :--- |
| `just statix` | Runs `statix check` to lint all Nix files in the repository. |


