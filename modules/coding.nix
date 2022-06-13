{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # python 
    python39Full # python3.9 full
    python39Packages.virtualenv # coding
    python39Packages.pip # coding
    python39Packages.pillow # coding
    python39Packages.setuptools # coding
    python39Packages.numpy
    libffi # coding used with pip
    gcc # coding used with pip

    git gti # svm
    gh # github util
    delta # git diff tool

    # golang
    go # coding

    # bash
    shellcheck # used with bash

    # C
    gnumake # coding make files
    glib # c wrappers

    # rust
    cargo # coding for rust
    pkg-config # packging with rust

    deno # javascript runtime
    nodejs # javascript runtime

    glow # markdown reader
    pandoc # convert markdown to any file
    hugo # website engine

    lice # license generator

    # nix
    nix-prefetch-git # git package util
  ];
}
