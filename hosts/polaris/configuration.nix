# Helsinki - Dedicated Database & Analytics Node
# Purpose: TimescaleDB for 7-year DUX backtest data (1TB NVMe for data)
# Hardware: Hetzner AX41 — AMD Ryzen 5 3600, 64GB RAM, 2x 512GB NVMe
# Location: Finland, HEL1
{ config, pkgs, lib, ... }:

{
  imports = [
    ./disko.nix
    ../../modules/server.nix
    ../../modules/dotfiles.nix
    ../../modules/security.nix
    ../../modules/monitoring.nix
    ../../modules/utilities.nix
  ];

  # GRUB for dedicated server
  boot.loader.grub.enable = true;

  networking.hostName = "polaris";

  # DHCP for public IP
  networking.useDHCP = true;

  time.timeZone = "Europe/Helsinki";

  # Disable auto-upgrade for remote servers - can't physically rescue if it breaks
  system.autoUpgrade.enable = lib.mkForce false;

  # Hardware watchdog - auto-reboot if system freezes (critical for remote servers)
  # systemd pings the watchdog every 30s; if it misses 3 pings (90s), hardware reboots
  systemd.watchdog = {
    runtimeTime = "90s";
    rebootTime = "120s";
  };

  # Keep SSH accessible even if Tailscale dies - bind to public IP too
  services.openssh.listenAddresses = [
    { addr = "0.0.0.0"; port = 22; }
  ];

  # Disable reverse path filter - it drops Tailscale/WireGuard packets
  # when k3s/flannel routing table changes make the rpfilter think
  # legitimate packets are spoofed. This is the root cause of the
  # recurring Tailscale disconnects that crash the server.
  networking.firewall.checkReversePath = false;

  # Auto-restart Tailscale if it crashes
  systemd.services.tailscaled.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = 5;
  };

  # Auto-restart k3s if it loses connection for too long
  systemd.services.k3s.serviceConfig = {
    WatchdogSec = lib.mkForce 300;  # k3s must ping systemd every 5 min or get restarted
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "docker-28.5.2" ];

  # Latest kernel for Ryzen optimizations
  # Crash monitor - logs NIC state, temps, conntrack every 10s for RCA
  systemd.services.crash-monitor = {
    description = "Polaris NIC crash monitor";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      User = "miguel";
      ExecStart = "/home/miguel/crash-monitor.sh";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # Pinned to 6.12 LTS - kernel 6.19 causes instability on AX41 hardware.
  # See: https://forum.proxmox.com/threads/pve9-hetzner-ax41-kernel-panic.171063/
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  # Longhorn storage support (for k8s persistent volumes)
  services.openiscsi = {
    enable = true;
    name = "iqn.2026-07.nixos:polaris";
  };
  boot.kernelModules = [ "iscsi_tcp" ];

  # Longhorn expects binaries in /usr/bin + data dir for TimescaleDB
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

  # Strict firewall — only SSH exposed, k8s traffic via Tailscale
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

  # k3s agent — joins Orion control plane via Tailscale
  services.k3s = {
    role = lib.mkForce "agent";
    serverAddr = lib.mkForce "https://100.127.233.30:6443";  # Orion via Tailscale
    tokenFile = lib.mkForce "/etc/k3s/token";
    extraFlags = lib.mkForce (toString [
      "--flannel-iface=tailscale0"
      "--node-label=topology.kubernetes.io/zone=eu-north"
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
        ${pkgs.tailscale}/bin/tailscale up --authkey="$(cat /etc/tailscale/authkey)" --ssh --accept-routes --hostname=polaris
        echo "Tailscale connected with auth key"
      else
        echo "No auth key found at /etc/tailscale/authkey — manual connection required"
      fi
    '';
  };

  # PostgreSQL/TimescaleDB tuning (extends server.nix sysctl with mkForce)
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkForce 1;
    "vm.dirty_ratio" = lib.mkForce 40;
    "vm.dirty_background_ratio" = lib.mkForce 10;
    "vm.overcommit_memory" = lib.mkForce 2;
    "vm.overcommit_ratio" = lib.mkForce 90;
    "kernel.shmmax" = lib.mkForce 17179869184;
    "kernel.shmall" = lib.mkForce 4194304;
  };

  system.stateVersion = "25.11";
}
