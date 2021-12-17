{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    python3 # coding
    python37Full # python3.7 full
    libffi # coding used with pip
    python37Packages.virtualenv # coding
    python37Packages.pip # coding
    gcc # coding used with pip
    python37Packages.pillow # coding
    python37Packages.setuptools # coding
    git # coding
    go # coding
    shellcheck # used with bash
    gnumake # coding make files
    glib # c wrappers
    cargo # coding for rust
    pkg-config # packging with rust

    deno # javascript runtime
    nodejs # javascript runtime

    pandoc # convert markdown to any file

    gh # github util
    delta # git diff tool
  ];
}
