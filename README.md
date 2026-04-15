# NixOS Configuration
Est. Feb 2024

My always evolving Nix flake. Declarative configurations across all systems in my Homelab:

- MacBookPro M1
- Desktop configuration
- Amazon EC2 Graviton (aarch64) instance
- Lenovo ThinkCentre M700 (Home-Assistant)
- Beelink GTR5 as a Proxmox host:
  - Customized stage-1 boot to start Tailscale, enabling SSH access to unlock the ZFS encrypted root device.
  - Multiple VMs to run self-hosted applications for monitoring and various services.
- Raspberry Pi 4s:
  - Blocky (Local DNS / Ad-blocking)
  - OctoPrint (3D printer server + plugins)

## Migration to flake-parts
While investigating the benefits of the dendritic pattern, I came across `flake-parts` and the benefits were too hard to ignore. It offers immediate benfits, like handling `system` and multi-arch packages, cleaning up my `flake.nix` layout and the ability to define multiple flake modules within the same file. This last feature is the biggest benefit, as it has drastically cleaned up the file structure of my repository.

By using `vic/import-tree` to bulk-import the `modules/` directory, I've eliminated rigid folder structures and the need to wrap everything in `mkEnableOption`. System profiles are now defined by the individual flake modules they import. Most of these configurations are enabled by default but some shared modules (like services and containers) retain explicit enable options for granular control.

I have also dropped home-manager as I do not need it outside of NixOS and nix-darwin. Everything I had previously used it for could be accomplished using native nix or nix-darwin modules. User environments are now managed directly through `makeWrapper`, `ExecStart` arguments, or environment variables defined via nix.

## Structure

`vic/import-tree` imports all files in my `modules` directory. The directory structure within `modules` does not matter but is "organized" by the flake module name.

For example, `apps/` contains configurations declaring `flake.modules.<system>.apps`, where `<system>` is one of `nixos`, `darwin` or `generic`.

```
├── lib/                   # Custom Nix library functions (alloy, traefik, hyprconfg, etc)
├── modules/
│   ├── apps/              # Desktop applications (Brave, Discord, Obsidian, etc.)
│   ├── attic/             # AtticD module (Nix binary caching)
│   ├── base/              # Core system configurations (networking, sops, sshd, zsh)
│   ├── containers/        # Containers (Grafana, Gitea, Traefik, etc.)
│   ├── desktop/           # Hyprland, Waybar, fonts, and graphical environments
│   ├── dev/               # Developer tools (git, tmux, direnv)
│   ├── home-assistant/    # Home-Assistant configurations, templates, and integrations
│   ├── hosts/             # Host-specific system configurations
│   ├── nixvim/            # Neovim configuration
│   ├── octoprint/         # Declarative OctoPrint configuration
│   ├── services/          # Services (Alloy, Backups, Tailscale, Loki)
│   └── packages/          # perSystem packages
├─ flake-parts.nix         # Imports flake-parts.flakeModules.modules
├─ generic.nix             # Auto-imports 'generic' modules
├─ options.nix             # Define deferredModules options
├─ overlays.nix            # Overlays for unstable and customPkgs
└─ systems.nix             # Available systems to target

```

## Helper Script

I'm utilizing  [`justfile`](https://github.com/casey/just) and a wrapper script ([`nix.sh`](./nix.sh)) to simplify common Nix operations.

|**Command**|**Description**|
|---|---|
|`just rebuild`|Rebuilds the configuration for the current host (local NixOS or Darwin).|
|`just <hostname>`|Rebuilds the configuration for a specific remote NixOS host (e.g., `just c137`).|
|`just build <target>`|Builds artifacts (e.g., configurations found under `flake.nix` packages).|
|`just update <input>`|Updates a specific flake input (e.g., `just update nixpkgs`).|
|`just update all`|Updates all flake inputs in `flake.lock`.|
|`just local <input>`|Switches a flake input to a local path for development.|
|`just attic <hostname>`|Builds and pushes a host's derivation to the [Attic](https://github.com/zhaofengli/attic) binary cache.|
|`just attic all`|Builds and pushes derivations for all hosts to the Attic cache.|
|`just statix`|Lints all Nix files in the repository with `statix check`.|

## Highlights

### Stage-1 Tailscale & LUKS

[Proxbox1](./modules/hosts/proxbox1/stage1-boot.nix) is configured with Tailscale and an SSH daemon running inside the `initrd` (Stage-1 boot). As most NUCs or small form-factor devices do not have IPMI, this allows me to configure an encrypted root device that does not require physical access to unlock.

I can SSH into the pre-boot environment over my Tailnet, unlock a LUKS-encrypted keystore containing my ZFS encryption key and complete the boot process.

### Dynamic DNS Automation (Blocky)

One of the primary advantages of using `flake-parts` is using Nix functions to scrape `self.nixosConfigurations` during evaluation.

The [blocky](./modules/blocky/blocky.nix) module looks for specific options under `mine.services.*` and `mine.containers.*`. If a service is `enabled` and has a `subdomain` option set, it is automatically injected into blocky's `customDNS.mapping` configuration. When a new service is deployed or decommissioned, all that is required is for the hosts with the `blocky` module to be rebuilt.

### Container Version Checks

A custom Python script reads the `org.opencontainers.*` labels on deployed Docker images to check for upstream updates. It sends notifications via Gotify and is scheduled as a systemd service via a systemd timer. Service failures will also send notifications via systemd `onFailure`.

### Homelab Backups

A custom Python script to automate backups, file rotation and inventory reports. Uses docker labels or environment variables for configuration, see [README.md](./modules/packages/homelab-backup/README.md) for more details on the script. Backups are executed via systemd services and scheudled using systemd timers. See [mkBackupService](./lib/backup.nix) function for various configuration options, including extra packages, addtional environment variables, or `postStart` and `preStart` commands.
### Home-Assistant

Fully declarative [Home-Assistant](./modules/home-assistant/hass.nix) configuration, including integrations like AppDaemon, Zigbee2MQTT, Govee2MQTT, and MQTT. AppDaemon is a sandboxed Python environment for writing automations via Python instead of defining automations using the UI or YAML files. Various sensors and entities are also managed via Nix.

### OctoPrint

The [Octoprint](./modules/octoprint/octoprint.nix) module configures the Octoprint service, including [plugins](./modules/packages/octoprint312.nix) and configuring webcam streams via Traefik.

> Note: A lot of Octoprint plugins require Python 3.12 as they utilize the `future` module, which has been essentially deprecated as of Python 3.13 per [this](https://github.com/PythonCharmers/python-future/issues/640#issuecomment-2550964549). Since the majority of these plugins are old and are not really maintained, the easiest fix has been overriding the default Python package for Octoprint and its Plugins to use Python 3.12.

