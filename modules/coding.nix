{ config, pkgs, ... }:
let
  baseconfig = { allowUnfree = true; };
  porcupine = import <nixos-porcupine> { config = baseconfig; };
  unstable = import <nixos-unstable> { config = baseconfig; };
in
{
  environment.systemPackages = with pkgs; [
    # nix community tools
    nixpacks # app + docker build tool
    
    # python
    pipx # python universal pkg
    python311Full # python3.9 full
    python311Packages.virtualenv # coding
    python311Packages.pip # coding
    python311Packages.pillow # coding
    python311Packages.setuptools # coding
    python311Packages.numpy
    python311Packages.ipython # interactive python
    python311Packages.jupyter-core # ipython notebook
    python311Packages.notebook # ipython notebook
    poetry # pip alternative
    libffi # coding used with pip
    gcc # coding used with pip

    git gti git-lfs# svm
    gh # github util
    unstable.gh-dash # github dashboard
    delta # git diff tool

    # golang
    go # coding
    go-jira # jira cli

    # bash
    shellcheck # used with bash

    # C
    gnumake # coding make files
    glib # c wrappers

    # rust
    cargo # coding for rust
    rustc # rust compiler
    pkg-config # packging with rust

    # node
    deno # javascript runtime
    nodejs # javascript runtime
    prisma-engines # javascript tools
    pnpm # javascript runtime
    vite # javascript library
    yarn2nix # helper nodejs yarn nix pkgs tool
    nodePackages.typescript # installing typescript
    # nodePackages.winglang # installing winglang

    glow # markdown reader
    pdftk # pdf combine tool
    pandoc # convert markdown to any file
    img2pdf # convert jpg to pdfs
    ocrmypdf # convert pdt fo ocr pdf
    mupdf # pdf viewer
    hugo # website engine
    texlive.combined.scheme-full # latex
    texstudio # latex
    logseq # journal
    obsidian # journal

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
    python311Packages.python-lsp-server # python
    ccls # c/c++
    gopls # golang
    nodePackages.bash-language-server # bash
    nodePackages.dockerfile-language-server-nodejs # docker
    vscode-extensions.rust-lang.rust-analyzer # rust
    taplo # tolm
    nodePackages.yaml-language-server # yaml
    cuelsp # cuelang

    ngrok # development reverse proxy

    # AI dev tools
    unstable.aider-chat
  ];
}
