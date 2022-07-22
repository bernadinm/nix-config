{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # music producing software
    ardour # daw
    lmms # daw
    mixxx # audio mixer for dj
    calf # audio plugins for daw
    vcv-rack # modular synth

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

    # graphics editing
    inkscape # vector graphic editor

    # audio editing
    audacity

    # videography
    libsForQt5.kdenlive # video editing
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.opengl.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.opengl.driSupport32Bit = true;
}
