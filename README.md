# NixOS Configuration
Est. Feb 2024

My always evolving Nix flake ❄️. Declarative configurations across all systems in my Homelab:

 - MacBookPro M1
 - Desktop configuration
 - Amazon EC2 Graviton (aarch64) instance
 - Lenovo ThinkCentre M700 (Home-Assistant)
 - Beelink GTR5 as a ProxMox host:
    - Customized stage1-boot to start Tailscale enabling ssh access to unlock ZFS Encrypted root device.
    - Multiple VM's to run self-hosted applications for monitoring and various services.
 - Raspberry Pi 4's
    - Blocky (Local DNS/Ad-blocking)
    - Octoprint (3d printer server + plugins)

## Migration to flake-parts
I wanted to implement flake-parts after looking into it while exploring the buzz around the dendritic pattern.

I am now using vic/import-tree to bulk-import the modules directory instead of relying on tricky imports and rigid folder structures with everything being mkEnableOption'ed.

Now most configurations are enabled by default and the system profile is determined by which flake modules it imports. Shared modules (like services and containers) still utilize enable options to maintain granular control where needed.

One of the primary advantages of this new structure is the ability to use Nix functions to gain insight across all nixosConfigurations. Doing so allows me to automate local DNS by programmatically scraping the entire flake for specific options under `mine.services.*` and `mine.containers.*`. If a service is enabled and has a subdomain option set, it is automatically injected into the Blocky customDNS.mapping configuration. This automation ensures that local DNS records are dynamically managed as services are deployed or decommissioned across the homelab.

I've also moved away from home-manager since the majority of my systems run NixOS (or nix-darwin on MBP M1) and I can use native NixOS modules to accomplish my desired setup. This is done either via wrappers, passing config files via ExecStart or just declaring env variables pointing to config files in the nix-store.


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
