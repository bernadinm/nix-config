{ config, pkgs, ... }:

let
  baseconfig = { allowUnfree = true; };
  porcupine = import <nixos-porcupine> { config = baseconfig; };
  unstable = import <nixos-unstable> { config = baseconfig; };
in
{
  environment.systemPackages = with pkgs; [
    # base
    wget # system
    helix # editor
    vim # system
    neovim
    evince # pdf viewer
    #(neovim.override {
    #  vimAlias = true;
    #  configure = {
    #    customRC = builtins.readFile ./config/init.vim;
    #    packages.myPlugins = with pkgs.vimPlugins; {
    #    start = [
    #      vim-surround # Shortcuts for setting () {} etc.
    #      coc-nvim coc-git coc-highlight coc-python coc-rls coc-vetur coc-vimtex coc-yaml coc-html coc-json # auto completion
    #      vim-nix # nix highlight
    #      vimtex # latex stuff
    #      fzf-vim # fuzzy finder through vim
    #      nerdtree # file structure inside nvim
    #      rainbow # Color parenthesis
    #    ];
    #    opt = [];
    #    };
    #  };
    #})
    gum # cli glue tool
    tmux # system
    unzip # system
    rar # archives
    zip # archives
    p7zip # archives
    cksfv # sfv checksum
    bash # system interface
    terraform # automation
    whois # domain info
    file # linux description of file
    inetutils # telnet
    trash-cli # system
    mimic # tts
    gspeech # tts
    picotts # tts
    killall # system kill
    termite # terminal
    nap # code snippet save tool
    bc # calc
    jq # jsonquery
    yq # yamlquery
    yt-dlp # youtube dl
    ts # task spooler batch queue
    bind # dns utils dig nslookup
    ffmpeg  # multimedia tool
    visidata # csv parsing tool
    usbutils # lsusb
    # TODO(bernadinm): remove parquet sa it cannot build in 23.05
    # parquet-tools # parquet viewer
    epr # ebook reader
    eza # replacement for ls
    zoxide # alternative to cd
    restic # backup util

    navi # cheat files
    fzf # fuzzy find
    nixpkgs-fmt # nixfmt
    nix-index # nix-locate

    # ML
    # gpt2tc # machine learning
    unstable.mods # gpt cli generative

    bat # cut alt
    duf # df alt
    fd # find alt
    silver-searcher # ack alt
    ripgrep # grep alt
    ripgrep-all # grep alt
    tldr # man alt
    gping # ping alt
    hck # cut alt
    xh # curl alt
    httpie # curl alt

    pcmanfm # desktop cli
    neofetch # sysinfo
    freshfetch # sysinfo
    speedtest-cli # internet speed chk
    fast-cli # internet speed chk
    lynx # text browser
    aria # torrent
    gcalcli # google cal cli

    pup # html cli parser
    ddgr # search engine cli
    twilio-cli # cloud platform
  ];
}
