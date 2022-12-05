# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-22.05.tar.gz";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/gdrivesync.nix
      ../../modules/entertainment.nix
      ../../modules/security.nix
      ../../modules/virtualization.nix
      ../../modules/communication.nix
      ../../modules/monitoring.nix
      ../../modules/desktop.nix
      ../../modules/utilities.nix
      ../../modules/coding.nix
      ../../modules/calibre.nix
      <nixos-unstable/nixos/modules/services/networking/nebula.nix>
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Luna"; # Define your hostname.
  networking.networkmanager.enable = true; # Use networkmanager for wifi

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
  #time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp170s0.useDHCP = true;

  networking.extraHosts =
    ''
      192.168.100.2 lumina
    '';

  boot.kernelPackages = pkgs.linuxPackages_latest; #- for WiFi support

  nixpkgs.config.allowUnfree = true;

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw
  # Enable the X11 windowing system.

  # Required for Framework Laptop to help avoid screen tearing:
  # https://discourse.nixos.org/t/eliminate-screen-tearing-with-intel-mesa/14724
  services.xserver.videoDrivers = [ "intel" ];
  services.xserver.deviceSection = ''
    Option "DRI" "2"
    Option "TearFree" "true"
  '';

  home-manager.users.miguel.home.file =
    {
      ".config/i3/config".source =
        .config/i3/config;
    };

  home-manager.users.rachelle.home.file =
    {
      ".config/i3/config".source =
        .config/i3/config;
    };

  services.upower.enable = true;
  services.xserver = {
    # small addition from desktop.nix import
    monitorSection = ''
      DisplaySize 408 306
    '';
  };

  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/508642b3-eced-4e85-9c67-e6e85d946d96";
  boot.initrd.luks.devices.root.preLVM = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip pkgs.canon-cups-ufr2 ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;
  services.xserver.libinput.touchpad.naturalScrolling = true;
  services.xserver.libinput.touchpad.disableWhileTyping = true;
  services.xserver.libinput.mouse.disableWhileTyping = true;

  #hardware.trackpoint.programs.light.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Installing TLP for Battery Life Optimization
  services.tlp.enable = true;

  # hybrid sleep when press power button
  services.logind.extraConfig = ''
    HandlePowerKeyLongPress=poweroff
    HandlePowerKey=hibernate
    HandleLidSwitch=suspend-then-hibernate
    HandleLidSwitchExternalPower=hybrid-sleep
    IdleAction=hibernate
    IdleActionSec=15min
  '';

  # screen locker
  programs.xss-lock.enable = true;
  programs.xss-lock.lockerCommand = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 15 30";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ddcutil
    i2c-tools
    libinput-gestures
    pulseeffects-legacy
  ];

  # Monitor Control via CLI
  services.ddccontrol.enable = true;
  hardware.i2c.enable = true;

  # Enable Nebula Mesh Network
  services.nebula.networks.mesh = {
    staticHostMap = { "192.168.100.2" = [ "lumina.miguel.engineer:4242" ]; };
  };

  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xautolock.fprintAuth = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}
