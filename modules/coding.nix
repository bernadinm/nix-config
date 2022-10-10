{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  porcupine = import <nixos-porcupine> { config = baseconfig; };
  unstable = import <nixos-unstable> { config = baseconfig; };
in
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
    unstable.gh-dash # github dashboard
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
    rustc # rust compiler
    pkg-config # packging with rust

    deno # javascript runtime
    nodejs # javascript runtime

    glow # markdown reader
    pandoc # convert markdown to any file
    ocrmypdf # convert pdt fo ocr pdf
    hugo # website engine

    # build tool
    unstable.bazel

    lice # license generator

    # nix
    nix-prefetch-git # git package util
  ];
}
