#!/bin/sh

set -e

# DEPRECATED: This script is for legacy packer/vagrant builds only.
# For actual system rebuilds, always use flakes:
#   sudo nixos-rebuild switch --flake /home/miguel/git/bernadinm/nix-config#<hostname>

# Switch to non ssl channel as there are issues with certs
# TODO: fix this propperly by including the root certs.
nix-channel --remove nixos
nix-channel --add http://nixos.org/channels/nixos-unstable nixos
# LEGACY: nixos-rebuild switch --upgrade
echo "WARNING: Use flake-based rebuild instead"

# Cleanup any previous generations and delete old packa
nix-collect-garbage -d

