{ config, pkgs, ... }:

{
  # Note: unstable packages now available via pkgs.unstable overlay from flake.nix
  environment.systemPackages = with pkgs; [
    # music producing software
    ardour # daw
    lmms # daw
    mixxx # audio mixer for dj
    calf # audio plugins for daw
    # pkgs.unstable.vcv-rack # modular synth (temporarily disabled - build failing on 25.11)

    # gaming

    # wineWowPackages.staging
    # (winetricks.override {
    #   wine = wineWowPackages.staging;
    # })
    pkgs.unstable.wineWowPackages.full
    winetricks
    bottles
    sc-controller
    steam-run
    vulkan-tools
    pkgs.unstable.prismlauncher
    pkgs.unstable.lutris
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
    mpv
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
    # davinci-resolve # video editing
    shotcut # cross-platform video editor
  ];

  # music player daemon
  services.mpd.enable = true;
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
  hardware.graphics.enable32Bit = true;
}
