{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    wget # system
    vim # system
    neovim
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
    tmux # system
    unzip # system
    rar # archives
    cksfv # sfv checksum
    bash # system interface
    terraform # automation
    whois # domain info
    inetutils # telnet
    trash-cli # system
    mimic # tts
    gspeech # tts
    picotts # tts
    killall # system kill
    termite # terminal
    bc # calc
    jq # jsonquery
    youtube-dl # youtube dl
    ts # task spooler batch queue
    bind # dns utils dig nslookup
    ffmpeg # multimedia tool
    visidata # csv parsing tool

    navi # cheat files
    fzf # fuzzy find
    nixpkgs-fmt # nixfmt

    # ML
    # gpt2tc # machine learning

    bat # cut alt
    duf # df alt
    fd # find alt
    silver-searcher # ack alt
    ripgrep # grep alt
    tldr # man alt
    gping # ping alt
    hck # cut alt
    xh # curl alt

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
  ];
}
