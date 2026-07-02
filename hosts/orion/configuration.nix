# Orion - Remote Server
# Purpose: Remote k3s cluster node, offload workloads from astra
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/server.nix
    ../../modules/dotfiles.nix
    ../../modules/security.nix
    ../../modules/monitoring.nix
    ../../modules/utilities.nix
    ../../modules/coding.nix
  ];

  # Use GRUB for legacy BIOS boot (cloud VMs)
  # Device is set by disko based on disk configuration
  boot.loader.grub.enable = true;

  networking.hostName = "orion";

  # DHCP for public IP
  networking.useDHCP = true;

  time.timeZone = "America/New_York";

  nixpkgs.config.allowUnfree = true;

  # Latest kernel for AMD EPYC optimizations
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Longhorn storage support (for k8s persistent volumes)
  services.openiscsi = {
    enable = true;
    name = "iqn.2026-07.nixos:orion";
  };
  boot.kernelModules = [ "iscsi_tcp" ];

  # Longhorn expects binaries in /usr/bin
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
    "L+ /usr/bin/mount - - - - /run/current-system/sw/bin/mount"
    "L+ /usr/bin/umount - - - - /run/current-system/sw/bin/umount"
    "L+ /usr/bin/nsenter - - - - /run/current-system/sw/bin/nsenter"
  ];

  # Server packages
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

  # Strict firewall for public VPS - only SSH exposed
  # All k8s traffic goes through Tailscale
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" "cni0" ];
  };

  # SSH hardening for public internet
  services.openssh.settings = {
    PasswordAuthentication = lib.mkForce false;
    PermitRootLogin = lib.mkForce "no";
    KbdInteractiveAuthentication = false;
  };

  # Fail2ban for SSH brute-force protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  system.stateVersion = "25.11";
}
