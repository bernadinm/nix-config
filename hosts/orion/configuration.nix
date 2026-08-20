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
    ../../modules/k8s-lb.nix
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
  boot.kernelModules = [ "iscsi_tcp" "nvme_tcp" ]; # nvme_tcp: mount Mayastor volumes

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

  # Allow miguel to copy nix store paths for remote deployment
  nix.settings.trusted-users = [ "root" "miguel" ];

  # Override k3s to be the control-plane server
  services.k3s = {
    role = lib.mkForce "server";
    extraFlags = lib.mkForce (toString [
      "--write-kubeconfig-mode=644"
      "--disable=traefik"
      "--disable=servicelb"
      "--node-ip=100.127.233.30"  # Use Tailscale IP for kubelet
      "--flannel-iface=tailscale0"  # Use Tailscale for flannel VXLAN
      "--node-label=topology.kubernetes.io/zone=us-east"
      # RCA Aug 11 2026: dead/Evicted pods accumulated to 12,634 objects
      # (default threshold 12500) with zero GC, degrading kubelet status
      # sync cluster-wide. Lower threshold so cleanup happens automatically
      # long before it becomes a problem.
      "--kube-controller-manager-arg=terminated-pod-gc-threshold=1000"
      # 2026-08-19: converts orion's k3s datastore from embedded SQLite to
      # embedded etcd, in place, preserving existing cluster state (per
      # k3s's own docs: restarting an existing SQLite server with
      # --cluster-init does exactly this). Required so vega/rigel can join
      # as real control-plane members instead of plain agents - SQLite
      # can't be joined by additional servers at all. NOTE: once etcd is
      # initialized on a node, this and the datastore-related flags below
      # are permanently locked in - a later restart with different
      # datastore flags is silently ignored, not applied.
      "--cluster-init"
      # Reserves this hostname as a valid SAN on the API server cert now,
      # for the future kube-vip endpoint (separate task) - avoids a second
      # cert regeneration later. Doesn't need to resolve to anything yet.
      "--tls-san=k8s.bernad.in"
    ]);
  };

  # Matches the same allowlist entry already used on vega/polaris/luna
  # (docker-28.5.2 is flagged insecure upstream; orion's k3s server also
  # depends on docker for the containerd runtime).
  nixpkgs.config.permittedInsecurePackages = [ "docker-28.5.2" "electron-39.8.10" ];

  system.stateVersion = "25.11";
}
