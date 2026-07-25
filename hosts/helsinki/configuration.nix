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

  networking.hostName = "helsinki";

  # DHCP for public IP
  networking.useDHCP = true;

  time.timeZone = "Europe/Helsinki";

  nixpkgs.config.allowUnfree = true;

  # Latest kernel for Ryzen optimizations
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Longhorn storage support (for k8s persistent volumes)
  services.openiscsi = {
    enable = true;
    name = "iqn.2026-07.nixos:helsinki";
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
        ${pkgs.tailscale}/bin/tailscale up --authkey="$(cat /etc/tailscale/authkey)" --ssh --accept-routes --hostname=helsinki
        echo "Tailscale connected with auth key"
      else
        echo "No auth key found at /etc/tailscale/authkey — manual connection required"
      fi
    '';
  };

  # PostgreSQL tuning for 64GB RAM database workload
  boot.kernel.sysctl = {
    "vm.max_map_count" = 262144;
    "fs.inotify.max_user_watches" = 524288;
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    # PostgreSQL/TimescaleDB tuning
    "vm.swappiness" = 1;               # Minimize swap usage
    "vm.dirty_ratio" = 40;             # Allow more dirty pages before flush
    "vm.dirty_background_ratio" = 10;  # Background flush at 10%
    "vm.overcommit_memory" = 2;        # Don't overcommit — important for PG
    "vm.overcommit_ratio" = 90;        # Allow 90% of RAM to be committed
    "kernel.shmmax" = 17179869184;     # 16GB shared memory for PG
    "kernel.shmall" = 4194304;         # Shared memory pages
  };

  # Ensure /data directory has correct permissions for k8s PVs
  systemd.tmpfiles.rules = lib.mkAfter [
    "d /data 0755 root root -"
  ];

  system.stateVersion = "25.11";
}
