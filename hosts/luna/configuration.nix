# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz";
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
      ../../modules/timemachinebackup.nix
      # TODO(bernadinm): Replace Mesh Network for Zero Trust
      # <nixos-unstable/nixos/modules/services/networking/nebula.nix>
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
  networking.interfaces.wlp1s0.useDHCP = true;

  boot.kernelPackages = pkgs.linuxPackages_latest; #- for WiFi support

  nixpkgs.config.allowUnfree = true;

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw
  programs.niri.enable = true;
  # Enable the Wayland windowing system and the Sway desktop environment.
  # services.wayland = {
  #   enable = true;
  #   sway = {
  #     enable = false;
  #     extraPackages = with pkgs; [ swaylock swayidle swaynag ];
  #     extraSessionCommands = ''
  #       # Add any additional commands that should run when starting the sway session
  #     '';
  #   };
  # };

  home-manager.users.miguel.home.file =
    {
      # Update file paths for Sway
      ".config/sway/config".source =
        .config/sway/config;
      ".config/libinput-gestures.conf".source =
        .config/libinput-gestures.conf;
    };
  
  # San Francisco, California for Redshift for screen color changing
  home-manager.users.miguel = {
    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = 37.773972;
      longitude = -122.431297;
    };
  };

  home-manager.users.rachelle.home.file =
    {
      # Update file paths for Sway
      ".config/sway/config".source =
        .config/sway/config;
      ".config/libinput-gestures.conf".source =
        .config/libinput-gestures.conf;
    };

  services.upower.enable = true;
  services.auto-cpufreq.enable = true;
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
  services.printing.drivers = [ pkgs.hplip pkgs.canon-cups-ufr2 pkgs.epsonscan2 ];

    # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.touchpad.naturalScrolling = true;
  services.xserver.libinput.touchpad.disableWhileTyping = true;
  services.xserver.libinput.mouse.disableWhileTyping = true;
  services.xserver.xkbOptions = "ctrl:swap_lfctl_lfwin"; # swap ctrl + fn keys

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Installing TLP for Battery Life Optimization
  # services.tlp.enable = true;

  # hybrid sleep when press power button
  services.logind.extraConfig = ''
    HandlePowerKeyLongPress=poweroff
    HandlePowerKey=suspend-then-hibernate
    HandleLidSwitch=hibernate
    HandleLidSwitchExternalPower=ignore
    HandleLidSwitchDocked=ignore
    IdleAction=hibernate
    IdleActionSec=15min
  '';

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
  # TODO(bernadinm): Replace Mesh Network for Zero Trust
  # services.nebula.networks.mesh = {
  #   staticHostMap = { "192.168.100.2" = [ "lumina.miguel.engineer:4242" ]; };
  # };

  services.fwupd.enable = true; # firmware update tool
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xautolock.fprintAuth = true;

  # TODO(bernadinm): required for home manager 23.05
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11" # used for logseq and obsidian
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
