{ config, pkgs, ... }:

{
  imports =
    [
      ../modules/adblock.nix
    ];

  environment.systemPackages = with pkgs; [
    # base
    xclip # clipboard history
    xsel # clipboard select
    xorg.xev # discover keybindings
    x2goclient # remote desktop client

    torbrowser # browser
    chromium # browser
    google-chrome # browser

    playerctl # music control

    font-awesome # font
    compton # window property changer
    lxqt.compton-conf # window property config

    feh # wallpaper manager

    scrot # screen capture
    screenfetch # used with scrot

    unclutter # hides mouse during inactivity 

    # text file managers
    vifm # text file manager
    ranger # text file manager
    nnn # text file manager

    pavucontrol # visual sound control

    rofi # program launcher
    dmenu # program launcher
    dunst # system notification
    libnotify # system notification

    spectacle # screenshot capture util
    (texlive.combine {
      inherit (texlive) scheme-small titling collection-langfrench cm-super;
    })

    # Plasma desktop
    kdeplasma-addons
    kdeconnect
    kdenlive
    okular
    konversation
    fusuma
    kile # latex authoring tool for kde
    gwenview # gui file manager
  ];

  # San Francisco, California for Redshift for screen color changing
  location.provider = "manual";
  location.latitude = 37.773972;
  location.longitude = -122.431297;
  services.redshift = {
    enable = true;
    temperature = {
      day = 5500;
      night = 3200;
    };
  };

  # Allows services and hosts exposed on the local network via mDNS/DNS-SD
  services.avahi.enable = true;
  services.avahi.nssmdns = true;

  services.atd.enable = true;

  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraPackages = with pkgs; [
        dmenu #application launcher most people use
        rofi
        polybar
        clipit
        xorg.xprop
        xautolock # timer to lock screen
        i3-layout-manager
        i3status # gives you the default i3 status bar
        i3lock-fancy-rapid #default i3 screen locker
        i3blocks #if you are planning on using i3blocks over i3status

        compton
        lxqt.compton-conf

        feh # wallpaper manager
        vifm # graphic file manager
      ];
    };
  };

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  # See: https://github.com/NixOS/nixpkgs/commit/224a6562a4880195afa5c184e755b8ecaba41536
  boot.loader.systemd-boot.configurationLimit = 50;

  hardware.bluetooth.enable = true; # enable bluethooth
  services.touchegg.enable = true; # enable multi touch gesture

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.miguel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "video" "i2c" ]; # Enable ‘sudo’ for the user.
    description = "Miguel Bernadin";
  };

  users.users.rachelle = {
    isNormalUser = true;
    extraGroups = [ ]; # Enable ‘sudo’ for the user.
    description = "Rachelle Bernadin";
  };


}
