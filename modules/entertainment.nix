{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # music producing software
    ardour # daw
    lmms # daw
    mixxx # audio mixer for dj
    calf # audio plugins for daw

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
    multimc
    lutris
    eidolon
    krb5
    cmatrix
    _2048-in-terminal

    # drone configuration
    betaflight-configurator

    # multimedia
    vlc
    gimp
    libreoffice

    # Latex
    texlive.combined.scheme-full

    # photography
    darktable # editing

    # graphics editing
    inkscape # vector graphic editor

    # audio editing
    audacity
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.driSupport32Bit = true;
}
