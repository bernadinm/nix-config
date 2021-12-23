{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    wget # system
    vim # system
    unzip # system
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
    youtubeDL # youtube dl
    ts # task spooler batch queue
    bind # dns utils dig nslookup

    navi # cheat files
    fzf # fuzzy find
    nixpkgs-fmt # nixfmt

    # ML
    # gpt2tc # machine learning

    bat # cut alt
    duf # df alt
    fd # find alt
    ag # ack alt
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
