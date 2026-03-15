# NixOS Configuration
Est. Feb 2024

My always evolving Nix flake ❄️. Declarative configurations across all systems in my Homelab:

 - MacBookPro M1 darwinConfiguration (nix-darwin + home-manager)
 - Desktop configuration (nixos modules + home-manager)

 - Lenovo ThinkCentre M700 for Home-Assistant.

 - Beelink GTR5 as a ProxMox host:
    - Customized stage1-boot to enable Tailscale for ssh access to unlock ZFS Encrypted root device.
    - VM's to run applications for monitoring and self-hosted tools.

 - Raspberry Pi 4's used for Blocky (Local DNS/Ad-blocking) and Octoprint.

## Migration to flake-parts

I wanted to implement flake-parts after looking into it while exploring the buzz around the dendritic pattern.

I might be abusing it but it *feels* better than my prior implementation that required some odd imports, folder structures and everything being mkEnableOption'ed.

While I do still utilize a lot custom options, the bulk of my configurations are now enabled by default. They are now dictated by what flake modules are imported as my new implementation utilizes vic/import-tree to bulk import all nix files in my modules directory.

Flake-parts also enables me to have insight across my nixosConfigurations via nix functions. For example, the blocky module scrapes my nixosConfiguration for specific options and if found, includes them in blockys `customDNS.mapping` setting. It scrapes them for options: `mine.services.*` and `mine.containers.*`, if they are enabled and have a `subdomain` option defined, it will be included in the DNS list.

## Helper Script

This repository uses a [`justfile`](./justfile) and a wrapper script ([`nix.sh`](./nix.sh)) to simplify common Nix operations. Below is a summary of the available commands.

| Command | Description |
| :--- | :--- |
| `just rebuild` | Rebuilds the configuration for the current host (local NixOS or Darwin). |
| `just <hostname>` | Rebuilds the configuration for a specific remote NixOS host (e.g., `just c137`). |
| `just build <target>` | Builds artifacts (e.g., configurations found under flake.nix `packages`). |
| `just update <input>` | Updates a specific flake input (e.g., `just update nixpkgs`). |
| `just update all` | Updates all flake inputs in `flake.lock`. |
| `just local <input>` | Switches a flake input to a local path for development. |
| `just attic <hostname>` | Builds and pushes a host's derivation to the [Attic](https://github.com/zhaofengli/attic) binary cache. |
| `just attic all` | Builds and pushes derivations for all hosts to the Attic cache. |
| `just statix` | Lints all Nix files in the repository with `statix check`. |

## Highlights

WIP
