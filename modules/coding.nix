{ config, pkgs, ... }:

{
  # Note: unstable packages now available via pkgs.unstable overlay from flake.nix
  environment.systemPackages = with pkgs; [
    # nix community tools
    nixpacks # app + docker build tool
    
    # python
    pipx # python universal pkg
    python313 # python 3.13 (Full variant removed - Bluetooth/tkinter now included by default)
    python313Packages.virtualenv # coding
    python313Packages.pip # coding
    python313Packages.pillow # coding
    python313Packages.setuptools # coding
    python313Packages.numpy
    # python311Packages.ipython # interactive python
    python313Packages.jupyter-core # ipython notebook
    python313Packages.notebook # ipython notebook
    poetry # pip alternative
    libffi # coding used with pip
    gcc # coding used with pip

    git gti git-lfs# svm
    gh # github util
    pkgs.unstable.gh-dash # github dashboard
    delta # git diff tool

    # golang
    go # coding
    go-jira # jira cli

    # bash
    shellcheck # used with bash

    # C
    gnumake # coding make files
    glib # c wrappers

    # # rust
    # cargo # coding for rust
    # rustc # rust compiler
    # pkg-config # packging with rust

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
    poppler-utils # render pdfs pdf2text
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
    pkgs.unstable.bazel

    lice # license generator

    # nix
    nix-prefetch-git # git package util

    # language servers
    nil # nix
    marksman # markdown
    # python311Packages.python-lsp-server # python
    # python311Packages.python-lsp-server # python
    ccls # c/c++
    gopls # golang
    nodePackages.bash-language-server # bash
    dockerfile-language-server # docker
    vscode-extensions.rust-lang.rust-analyzer # rust
    taplo # tolm
    nodePackages.yaml-language-server # yaml
    cuelsp # cuelang

    ngrok # development reverse proxy

    # AI dev tools
    pkgs.unstable.aider-chat
    pkgs.unstable.claude-code
    pkgs.unstable.opencode
  ];
}
