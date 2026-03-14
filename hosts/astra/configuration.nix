# Astra - Standalone Server Configuration
# Purpose: GitHub Actions runner + k3s Kubernetes cluster
# This is a headless server (no desktop environment)

{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Server-specific modules
      ../../modules/server.nix
      ../../modules/backups.nix
      ../../modules/security.nix
      ../../modules/monitoring.nix
      ../../modules/utilities.nix
      ../../modules/coding.nix
    ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "astra"; # Define your hostname (lowercase for server)
  networking.networkmanager.enable = true; # Use networkmanager for wifi

  # Static IP configuration (optional - remove if using DHCP)
  # networking.interfaces.wlp170s0.ipv4.addresses = [{
  #   address = "192.168.100.50";
  #   prefixLength = 24;
  # }];
  # networking.defaultGateway = "192.168.100.1";
  # networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Use DHCP
  networking.useDHCP = false;
  networking.interfaces.wlp170s0.useDHCP = true;

  # bernadinm(todo): remove me
  # networking.extraHosts =
  #   ''
  #     192.168.100.2 lumina
  #   '';

  boot.kernelPackages = pkgs.linuxPackages_latest; #- for WiFi support

  nixpkgs.config.allowUnfree = true;

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw

  # Server mode - no desktop environment, no X server
  # All GUI settings removed for headless operation

  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/508642b3-eced-4e85-9c67-e6e85d946d96";
  boot.initrd.luks.devices.root.preLVM = true;

  # Server doesn't need printing or touchpad support

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Define the miguel user (required - was previously only in desktop.nix)
  users.users.miguel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "libvirtd" ];
    description = "Miguel Bernadin";
  };

  # Server power management - never sleep, always on
  # Power management is handled by server.nix module

  # Server-specific packages (k8s tools are in server.nix)
  environment.systemPackages = with pkgs; [
    htop
    btop
    ncdu
    tmux
    screen
    vim
    neovim
    git
    curl
    wget
    rsync
    tree
  ];

  # Firmware updates
  services.fwupd.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
