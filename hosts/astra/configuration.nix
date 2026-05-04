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
      ../../modules/dotfiles.nix
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

  # Static IP - eliminates DHCP DAD conflicts permanently.
  # Chose .148 because astra was historically on this address.
  networking.interfaces.wlp170s0.ipv4.addresses = [{
    address = "192.168.100.148";
    prefixLength = 24;
  }];
  networking.defaultGateway = {
    address = "192.168.100.1";
    interface = "wlp170s0";
  };
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Enable DHCP for ethernet only, WiFi stays static
  networking.useDHCP = false;
  networking.interfaces.wlp170s0.useDHCP = false;

  # bernadinm(todo): remove me
  # networking.extraHosts =
  #   ''
  #     192.168.100.2 lumina
  #   '';

  # Disable WiFi power management - prevents DORMANT mode that causes packet drops
  networking.networkmanager.wifi.powersave = false;

  boot.kernelPackages = pkgs.linuxPackages_latest; #- for WiFi support

  # Longhorn storage requirements
  services.openiscsi = {
    enable = true;
    name = "iqn.2026-03.nixos:astra";
  };
  boot.kernelModules = [ "iscsi_tcp" ];

  # Longhorn expects binaries in /usr/bin (NixOS uses /run/current-system/sw/bin)
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
    "L+ /usr/bin/mount - - - - /run/current-system/sw/bin/mount"
    "L+ /usr/bin/umount - - - - /run/current-system/sw/bin/umount"
    "L+ /usr/bin/nsenter - - - - /run/current-system/sw/bin/nsenter"
  ];

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
