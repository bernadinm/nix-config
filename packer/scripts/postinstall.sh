#!/bin/sh

set -e

# DEPRECATED: This script is for legacy packer/vagrant builds only.
# For actual system rebuilds, always use flakes:
#   sudo nixos-rebuild switch --flake /home/miguel/git/bernadinm/nix-config#<hostname>

# This script is no longer used - flakes handle all rebuilds now.
echo "WARNING: Use flake-based rebuild instead:
  sudo nixos-rebuild switch --flake /home/miguel/git/bernadinm/nix-config#<hostname>"

# Cleanup any previous generations and delete old packa
nix-collect-garbage -d

