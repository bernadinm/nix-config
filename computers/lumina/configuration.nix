# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <nixos-unstable/nixos/modules/services/networking/nebula.nix>
      # <nixos-unstable/nixos/modules/services/web-apps/keycloak.nix>
      ../../modules/gdrivesync.nix
      ../../modules/entertainment.nix
      ../../modules/security.nix
      ../../modules/virtualization.nix
      ../../modules/communication.nix
      ../../modules/monitoring.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  boot.initrd.luks.devices.nixos.device = "/dev/disk/by-uuid/0ec6024a-636d-4736-a299-83b3c071d9a9";
  boot.initrd.luks.devices.nixos.preLVM = true;
  services.ddclient = { enable = true; configFile = "/home/miguel/configs/ddclient/ddclient.conf"; }; # dynamicdns
  services.xserver.videoDrivers = [ "nvidia" ];
  # nixpkgs.config.allowUnfree = true;

  # Setting the hostname of NixOS
  networking.hostName = "Lumina";
  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw 
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
        clipit
        xorg.xprop
        xautolock # timer to lock screen
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

  ## Enable the X11 windowing system.
  #services.xserver.enable = true;

  ## Enable the Plasma 5 Desktop Environment.
  ## services.xserver.displayManager.sddm.enable = true;
  #services.xserver.displayManager.lightdm.enable = true;
  #services.xserver.desktopManager.pantheon.enable = true;

  environment.etc = {
    "resolv.conf".text = "nameserver 8.8.8.8\n";
  };

  services.bind = {
    enable = true;
    extraConfig = ''
      include "/var/lib/secrets/dnskeys.conf";
    '';
    zones = [
      rec {
        name = "lumina.miguel.engineer";
        file = "/var/db/bind/${name}";
        master = true;
        extraConfig = "allow-update { key rfc2136key.lumina.miguel.engineer.; };";
      }
    ];
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip ];

  services.avahi.enable = true; # sometimes needed for finding on network
  services.avahi.nssmdns = true;

  services.flatpak.enable = true;
  xdg.portal.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
  };

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver = {
    libinput.touchpad.naturalScrolling = true;
    libinput.enable = true;
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

  hardware.acpilight.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    vim
    unzip
    python3
    python37Packages.virtualenv
    python37Packages.pip
    gcc
    libffi
    python37Packages.pillow
    python37Packages.setuptools
    git
    bash
    xclip
    google-chrome
    glib
    ddcutil
    i2c-tools
    terraform
    fast-cli
    libinput-gestures
    pcmanfm
    gspeech
    lynx
    whois
    trash-cli
    gnumake
    geekbench
    xsel
    mimic
    picotts
    bind
    ag
    ripgrep
    tigervnc
    aria
    killall
    w3m-full
    bc
    gh
    nnn
    nixpkgs-fmt

    #(import (builtins.fetchTarball https://github.com/hercules-ci/arion/tarball/master) {}).arion

    unstable.x2goserver
    x2goclient
    ncdu

    betaflight-configurator

    torbrowser
    chromium

    kdeplasma-addons
    kdeconnect
    kdenlive
    okular
    yakuake
    termite
    konversation
    fusuma
    gwenview
    navi
    spectacle
    kile
    (texlive.combine {
      inherit (texlive) scheme-small titling collection-langfrench cm-super;
    })

    nodejs_latest

    # Fonts
    font-awesome

    # monitoring
    cointop
    htop

    # ML
    gpt2tc
  ];

  # Monitor Control via CLI
  services.ddccontrol.enable = true;
  hardware.i2c.enable = true;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "plasmashell";

  # Open ports in the firewall.
  networking.enableIPv6 = false;
  networking.firewall.allowedTCPPorts = [ 3389 80 443 4242 ];
  networking.firewall.allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
  networking.firewall.allowedUDPPortRanges = [{ from = 1714; to = 1764; }];

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Install the flakes edition
  nix.package = pkgs.nixFlakes;
  # Enable the nix 2.0 CLI and flakes support feature-flags
  nix.extraOptions = ''
    experimental-features = nix-command flakes 
  '';

  # List services that you want to enable:

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
