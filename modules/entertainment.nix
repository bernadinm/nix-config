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
    # eidolon # removed in 25.11 - unmaintained upstream
    krb5

    # Retro Gaming - RetroArch + Cores (Tiny Best Set GO)
    retroarch
    libretro.mgba              # GBA
    libretro.snes9x            # SNES
    libretro.genesis-plus-gx   # Genesis, Master System, Game Gear, Sega CD
    libretro.nestopia          # NES
    libretro.beetle-psx-hw     # PlayStation
    libretro.fbneo             # Arcade, Neo Geo
    libretro.mame2003-plus     # Arcade (MAME 2003+)
    libretro.beetle-pce        # TurboGrafx-16
    libretro.stella            # Atari 2600
    libretro.gambatte          # Game Boy, Game Boy Color
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
    kdePackages.kdenlive # video editing
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
