{ config, pkgs, ... }:

let
  baseconfig = { allowUnfree = true; };
  porcupine = import <nixos-porcupine> { config = baseconfig; };
  unstable = import <nixos-unstable> { config = baseconfig; };
in
{
  environment.systemPackages = with pkgs; [
    # music producing software
    ardour # daw
    lmms # daw
    mixxx # audio mixer for dj
    calf # audio plugins for daw
    unstable.vcv-rack # modular synth

    # gaming

    # wineWowPackages.staging
    # (winetricks.override {
    #   wine = wineWowPackages.staging;
    # })
    unstable.wineWowPackages.full
    winetricks
    bottles
    sc-controller
    steam-run
    vulkan-tools
    minecraft
    unstable.prismlauncher
    unstable.lutris
    eidolon
    krb5
    cmatrix
    _2048-in-terminal
    vitetris
    uchess
    nsnake
    moon-buggy
    nudoku
    ninvaders
    njam # pacman
    bsdgames # install trek fortune boggle worm gomoku backgammon

    # drone configuration
    betaflight-configurator
    opentx
    edgetx
    dfu-util

    # multimedia
    vlc
    libreoffice # alt word
    gimp # alt photoshop
    scribus # alt indesign
    krita # alt illustrator

    # Latex
    texlive.combined.scheme-full

    # photography
    darktable # editing
    imagemagick # image converstion tool

    # graphics editing
    inkscape # vector graphic editor

    # audio editing
    audacity

    obs-studio # video recording/streaming

    # videography
    libsForQt5.kdenlive # video editing
    # TODO(bernadinm): removing this below due to nixos 23.05 errors
    # davinci-resolve # video editing
  ];

  # music player daemon
  services.mpd.enable = true;
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.driSupport32Bit = true;
}
