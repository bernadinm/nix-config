# Vega - High-Memory Database & Compute Node
# Purpose: TimescaleDB, k3s agent, future inference workloads
# Hardware: Hetzner Auction - AMD EPYC 7502P, 576GB RAM, 2x 960GB NVMe
# Location: Germany, FSN1-DC20
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

  # GRUB for dedicated server
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "/dev/nvme0n1" ];

  networking.hostName = "vega";

  # === NETWORK FIX: Use systemd-networkd with static IP (RCA Jul 27 2026) ===
  # Root cause: dhcpcd was managing veth interfaces from K3s containers and
  # USB ethernet adapter, causing it to delete the main route via enp195s0.
  # Solution: Use systemd-networkd with static IP per Hetzner recommendations.

  # Disable dhcpcd entirely - it conflicts with container networking
  networking.useDHCP = false;

  # Enable systemd-networkd for network management
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;

    # Main WAN interface - static IP configuration
    networks."10-wan" = {
      matchConfig.Name = "enp195s0";
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = "no";
      };
      addresses = [
        { Address = "167.235.115.39/26"; }
      ];
      routes = [
        { Gateway = "167.235.115.1"; }
      ];
      linkConfig.RequiredForOnline = "routable";
    };

    # Ignore veth interfaces from containers - let K3s manage them
    networks."99-veth-ignore" = {
      matchConfig.Name = "veth*";
      linkConfig.Unmanaged = "yes";
    };

    # Ignore cni interfaces from K3s
    networks."99-cni-ignore" = {
      matchConfig.Name = "cni*";
      linkConfig.Unmanaged = "yes";
    };

    # Ignore flannel interfaces
    networks."99-flannel-ignore" = {
      matchConfig.Name = "flannel*";
      linkConfig.Unmanaged = "yes";
    };
  };

  # === DNS FIX: prevent Tailscale MagicDNS circular dependency ===
  # RCA Jul 27 2026: 3 reboots in 13 hours caused by:
  #   Tailscale MagicDNS (100.100.100.100) was sole nameserver →
  #   Tailscale hiccup → DNS fails → Tailscale can't resolve DERP →
  #   K3s loses control plane → machine unreachable → hard reboot.
  # Fix: Hetzner DNS + Cloudflare as primary, Tailscale DNS disabled.
  networking.nameservers = [ "185.12.64.1" "185.12.64.2" "1.1.1.1" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "185.12.64.1" "1.1.1.1" "8.8.8.8" ];
  };
  services.tailscale.extraUpFlags = [ "--accept-dns=false" ];

  time.timeZone = "Europe/Berlin";

  # Disable auto-upgrade for remote servers
  system.autoUpgrade.enable = lib.mkForce false;

  # Hardware watchdog - auto-reboot if system freezes
  systemd.settings.Manager = {
    RuntimeWatchdogSec = "90s";
    RebootWatchdogSec = "120s";
  };

  # Keep SSH accessible even if Tailscale dies
  services.openssh.listenAddresses = [
    { addr = "0.0.0.0"; port = 22; }
  ];

  # Auto-restart Tailscale if it crashes
  systemd.services.tailscaled.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = 5;
  };

  # k3s watchdog disabled - k3s doesn't support NOTIFY_SOCKET,
  # so WatchdogSec causes false kills and server reboots

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "docker-28.5.2" "electron-39.8.10" ];

  # Latest kernel for EPYC optimizations
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Longhorn storage support (for k8s persistent volumes)
  services.openiscsi = {
    enable = true;
    name = "iqn.2026-07.nixos:vega";
  };
  boot.kernelModules = [ "iscsi_tcp" ];

  # Longhorn expects binaries in /usr/bin + data dir
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
    "L+ /usr/bin/mount - - - - /run/current-system/sw/bin/mount"
    "L+ /usr/bin/umount - - - - /run/current-system/sw/bin/umount"
    "L+ /usr/bin/nsenter - - - - /run/current-system/sw/bin/nsenter"
    "d /data 0755 root root -"
  ];

  # Server packages
  environment.systemPackages = with pkgs; [
    htop
    btop
    ncdu
    tmux
    vim
    neovim
    git
    curl
    wget
    rsync
    tree
  ];

  # Loose reverse path filter - required for Tailscale + k3s/flannel
  # Strict mode drops WireGuard UDP packets due to asymmetric routing
  # See: https://wiki.nixos.org/wiki/Tailscale, NixOS PR #170851
  networking.firewall.checkReversePath = "loose";
  services.tailscale.useRoutingFeatures = "both";

  # Strict firewall - only SSH exposed, k8s traffic via Tailscale
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

  # k3s agent - joins Orion control plane via Tailscale
  services.k3s = {
    role = lib.mkForce "agent";
    serverAddr = lib.mkForce "https://100.127.233.30:6443";
    tokenFile = lib.mkForce "/etc/k3s/token";
    extraFlags = lib.mkForce (toString [
      "--flannel-iface=tailscale0"
      "--node-label=topology.kubernetes.io/zone=eu-central"
      "--node-label=node.kubernetes.io/role=database"
    ]);
  };

  # k3s depends on Tailscale being connected
  systemd.services.k3s = {
    after = [ "tailscale-autoconnect.service" ];
    wants = [ "tailscale-autoconnect.service" ];
  };

  # Auto-authenticate Tailscale on first boot
  systemd.services.tailscale-autoconnect = {
    description = "Automatic Tailscale connection";
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      sleep 5
      status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // "Unknown"')
      if [ "$status" = "Running" ]; then
        echo "Tailscale already connected"
        exit 0
      fi
      if [ -f /etc/tailscale/authkey ]; then
        ${pkgs.tailscale}/bin/tailscale up --authkey="$(cat /etc/tailscale/authkey)" --ssh --accept-routes --hostname=vega
        echo "Tailscale connected with auth key"
      else
        echo "No auth key found at /etc/tailscale/authkey - manual connection required"
      fi
    '';
  };

  # PostgreSQL/TimescaleDB tuning for 576GB RAM
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkForce 1;
    "vm.dirty_ratio" = lib.mkForce 40;
    "vm.dirty_background_ratio" = lib.mkForce 10;
    "vm.overcommit_memory" = lib.mkForce 2;
    "vm.overcommit_ratio" = lib.mkForce 90;
    "kernel.shmmax" = lib.mkForce 309237645312;  # 288GB - half of 576GB
    "kernel.shmall" = lib.mkForce 75497472;       # shmmax / 4096
  };

  system.stateVersion = "25.11";
}
