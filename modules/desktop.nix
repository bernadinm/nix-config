{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # base
    google-chrome
    xclip
    xsel
    x2goclient
    torbrowser
    chromium

    # Plasma desktop
    kdeplasma-addons
    kdeconnect
    kdenlive
    okular
    konversation
    fusuma
    gwenview

    # Fonts
    font-awesome
    compton
    lxqt.compton-conf

    feh # wallpaper manager

    # text file managers
    vifm
    ranger
    nnn

    rofi
    dmenu
    dunst # system notification
    libnotify # system notification

    w3m-full

    spectacle # screenshot capture util
    kile # latex authoring tool for kde
    (texlive.combine {
      inherit (texlive) scheme-small titling collection-langfrench cm-super;
    })

  ];

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
