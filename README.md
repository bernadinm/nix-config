# NixOS Configuration (Flake-based)

## Usage

This repository contains my NixOS configuration using **Nix Flakes** for reproducible, declarative system management. This includes setting up users and installing system-level and user-specific programs.

Starting out with Nix? Check out:
- [NixOS Cheatsheet](https://nixos.wiki/index.php?title=Cheatsheet&useskin=vector)
- [Nix Flakes Guide](https://nixos.wiki/wiki/Flakes)

### How to Build/Rebuild Hosts

This configuration uses **Nix Flakes** for improved reproducibility and multi-host management.

#### Initial Setup
```bash
git clone https://github.com/bernadinm/nix-config.git
cd nix-config
git submodule update --init --recursive # fetch external vendor as submodules
```

#### Rebuild System (Flake-based)
```bash
# For Luna (Framework Laptop)
sudo nixos-rebuild switch --flake /home/miguel/git/bernadinm/nix-config#luna

# For Astra
sudo nixos-rebuild switch --flake /home/miguel/git/bernadinm/nix-config#astra

# For Lumina
sudo nixos-rebuild switch --flake /home/miguel/git/bernadinm/nix-config#lumina

# Shorthand (from within the nix-config directory)
sudo nixos-rebuild switch --flake .#luna
```

### Version Management

#### Upgrade to Latest nixpkgs
```bash
# Update flake.lock to latest nixpkgs version
nix flake update

# Rebuild with new packages
sudo nixos-rebuild switch --flake .#luna
```

#### Selective Package Updates
```bash
# Update only nixpkgs (stable)
nix flake lock --update-input nixpkgs

# Update only nixpkgs-unstable
nix flake lock --update-input nixpkgs-unstable

# See what would update (dry-run)
nix flake lock --update-input nixpkgs --dry-run
```

### Available Packages

- **Stable packages**: `pkgs.firefox` (from nixos-25.11)
- **Unstable packages**: `pkgs.unstable.firefox` (from nixos-unstable)

The flake overlay makes unstable packages available via `pkgs.unstable.*`

## Architecture

### Hosts
- **Luna**: Framework Laptop 13 (Hyprland/Wayland)
- **Astra**: Desktop workstation
- **Lumina**: Desktop workstation

### Flake Structure
- `flake.nix`: Main flake configuration with multi-host support
- `flake.lock`: Pinned versions of all inputs (nixpkgs, home-manager, etc.)
- `hosts/*/configuration.nix`: Host-specific configurations
- `modules/*.nix`: Shared modules (desktop, coding, entertainment, etc.)

## Accomplished

- [x] Import specific groups of apps via modules
- [x] Source external git repositories using git submodules
- [x] Set up [Home Manager](https://nixos.wiki/wiki/Home_Manager)
- [x] Migrate to Nix Flakes for reproducibility
- [x] Migrate from X11 to Wayland (Hyprland)
- [x] Multi-host management via flakes

## Next Steps

- [ ] Installing instructions for cloud and local use (virtualbox)
- [ ] Installing instructions for Raspberry Pi
- [ ] Document MCP server setup for Claude Code

# Authors

Originally created and maintained by [Miguel Bernadin](https://github.com/bernadinm).

# License

Apache 2 Licensed. See LICENSE for full details.
