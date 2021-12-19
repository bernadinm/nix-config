{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # python 
    python3 # coding
    python37Full # python3.7 full
    python37Packages.virtualenv # coding
    python37Packages.pip # coding
    python37Packages.pillow # coding
    python37Packages.setuptools # coding
    libffi # coding used with pip
    gcc # coding used with pip

    git # svm
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

    pandoc # convert markdown to any file
  ];
}
