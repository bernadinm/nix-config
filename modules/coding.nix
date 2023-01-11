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
    unstable.cargo # coding for rust
    unstable.rustc # rust compiler
    unstable.pkg-config # packging with rust

    deno # javascript runtime
    nodejs # javascript runtime
    nodePackages.typescript # installing typescript

    glow # markdown reader
    pandoc # convert markdown to any file
    ocrmypdf # convert pdt fo ocr pdf
    mupdf # pdf viewer
    hugo # website engine

    # cuelang
    cue

    # build tool
    unstable.bazel

    lice # license generator

    # nix
    nix-prefetch-git # git package util
  ];
}
