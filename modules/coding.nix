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

    git gti git-lfs# svm
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
    yarn2nix # helper nodejs yarn nix pkgs tool
    nodePackages.typescript # installing typescript

    glow # markdown reader
    pdftk # pdf combine tool
    pandoc # convert markdown to any file
    ocrmypdf # convert pdt fo ocr pdf
    mupdf # pdf viewer
    hugo # website engine
    texlive.combined.scheme-full # latex
    texstudio # latex
    unstable.logseq # journal

    # cuelang
    cue

    # github actions
    act

    # build tool
    unstable.bazel

    lice # license generator

    # nix
    nix-prefetch-git # git package util

    # language servers
    nil # nix
    marksman # markdown
    python310Packages.python-lsp-server # python
    ccls # c/c++
    gopls # golang
    nodePackages.bash-language-server # bash
    nodePackages.dockerfile-language-server-nodejs # docker
    vscode-extensions.rust-lang.rust-analyzer # rust
    taplo # tolm
    nodePackages.yaml-language-server # yaml
    cuelsp # cuelang

    ngrok # development reverse proxy
  ];
}
