# Server-specific configuration for standalone NixOS servers
# This module provides:
# - GitHub Actions self-hosted runner
# - k3s Kubernetes cluster
# - Headless operation (no desktop environment)
# - SSH server
# - Tailscale for remote access

{ config, lib, pkgs, ... }:

{
  # Server user account
  users.users.miguel = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "libvirtd" ];
    description = "Miguel Bernadin";
  };

  # Headless server - no X11/Wayland
  services.xserver.enable = false;

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # Allow password auth for remote management
      PermitRootLogin = "no";
    };
  };

  # Tailscale for secure remote access
  services.tailscale.enable = true;

  # k3s Kubernetes cluster (single-node)
  # GitHub Actions runners will run as pods in k3s using Actions Runner Controller
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--write-kubeconfig-mode=644"
      "--disable=traefik"  # Disable built-in traefik, install nginx-ingress instead
      "--disable=servicelb" # Disable servicelb, use MetalLB
    ];
  };

  # Enable Docker for k3s containerd runtime
  virtualisation.docker.enable = true;

  # Firewall rules for k3s
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22    # SSH
      6443  # k3s API server
      10250 # kubelet
      30900 # MinIO S3 API (NodePort)
      30901 # MinIO Console (NodePort)
    ];
    allowedUDPPorts = [
      8472  # k3s flannel VXLAN
    ];
    trustedInterfaces = [ "tailscale0" "cni0" ];
  };

  # Kubernetes tools and GitOps
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s  # Terminal UI for Kubernetes
    kubectx
    kustomize
    argocd
    flux
    redis # redis-cli for debugging k3s/k8s services
  ];

  # Create k3s manifests directory for GitOps
  system.activationScripts.k3sManifests = ''
    mkdir -p /var/lib/rancher/k3s/server/manifests
  '';

  # Auto-update and gc
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    channel = "https://nixos.org/channels/nixos-unstable";
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Performance tuning for server workloads
  boot.kernel.sysctl = {
    "vm.max_map_count" = 262144;  # For Elasticsearch and similar
    "fs.inotify.max_user_watches" = 524288;  # For k8s
    "net.ipv4.ip_forward" = 1;  # Required for k3s
    "net.bridge.bridge-nf-call-iptables" = 1;  # Required for k3s
  };

  # Load kernel modules for k3s
  boot.kernelModules = [ "br_netfilter" "overlay" ];

  # Never sleep/suspend
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Monitoring and logging
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=1month
  '';
}
