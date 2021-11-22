# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/gdrivesync.nix
      ../../modules/entertainment.nix
      ../../modules/security.nix
      ../../modules/virtualization.nix
      ../../modules/communication.nix
      ../../modules/monitoring.nix
      ../../modules/desktop.nix
      ../../modules/utilities.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Luna"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  hardware.bluetooth.enable = true; # enable bluethooth

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
  #time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp170s0.useDHCP = true;

  boot.kernelPackages = pkgs.linuxPackages_latest; #- for WiFi support
  services.fprintd.enable = true; #for fingerprint support
  
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
  services.printing.drivers = [ pkgs.hplip pkgs.canon-cups-ufr2];

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

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

  # Install the flakes edition
  nix.package = pkgs.nixFlakes;
  # Enable the nix 2.0 CLI and flakes support feature-flags
  nix.extraOptions = ''
    experimental-features = nix-command flakes 
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
