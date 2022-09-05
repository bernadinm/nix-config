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
    wineWowPackages.full
    winetricks
    bottles
    sc-controller
    steam-run
    vulkan-tools
    minecraft
    polymc
    lutris
    eidolon
    krb5
    cmatrix
    _2048-in-terminal
    uchess

    # drone configuration
    betaflight-configurator
    opentx
    edgetx
    dfu-util

    # multimedia
    vlc
    gimp
    libreoffice

    # Latex
    texlive.combined.scheme-full

    # photography
    darktable # editing
    imagemagick # image converstion tool

    # graphics editing
    inkscape # vector graphic editor

    # audio editing
    audacity

    # videography
    libsForQt5.kdenlive # video editing
    davinci-resolve # video editing
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.driSupport32Bit = true;
}
