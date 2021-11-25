{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    wget
    vim
    unzip
    python3
    python37Packages.virtualenv
    python37Packages.pip
    gcc
    libffi
    python37Packages.pillow
    python37Packages.setuptools
    git
    delta
    bash
    glib
    ddgr
    terraform
    fast-cli
    pcmanfm
    gspeech
    lynx
    whois
    trash-cli
    gnumake
    mimic
    picotts
    bind
    ag
    ripgrep
    aria
    killall
    bc
    gh
    termite
    neofetch

    navi
    fzf
    go
    nixpkgs-fmt

    # ML
    gpt2tc

    bat
  ];
}
