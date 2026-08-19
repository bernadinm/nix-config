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
  boot.kernelModules = [ "iscsi_tcp" "nvme_tcp" ]; # nvme_tcp: mount Mayastor volumes

  # OpenEBS Mayastor storage node: io-engine needs 2MiB hugepages (2GiB
  # reserved); DiskPool backing file lives on /data, bind-mounted to the
  # only path the io-engine container mounts. blk_size=4096 to match rigel.
  boot.kernel.sysctl."vm.nr_hugepages" = 1024;
  fileSystems."/var/local/mayastor/io-engine" = {
    device = "/data/mayastor";
    options = [ "bind" ];
  };

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
  # RustDesk server (hbbs/hbbr) runs hostNetwork on this node, so unlike
  # NodePort services these ports actually go through this chain - opened
  # deliberately for it, everything else stays closed.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 21115 21116 21117 ];
    allowedUDPPorts = [ 21116 ];
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

  # 2026-08-19: promoted from agent to server (control-plane + etcd member)
  # as part of converting to a real 3-node HA control plane (orion + vega +
  # rigel) - see nix-config git log for the full rationale. Join mechanics
  # (serverAddr, tokenFile) are unchanged - vega already proved it can
  # reach orion and authenticate with this exact token as an agent; only
  # the role changes; k3s handles the rest automatically now that orion's
  # datastore is etcd instead of SQLite (embedded HA requires etcd -
  # additional servers cannot join a SQLite-backed cluster at all).
  services.k3s = {
    role = lib.mkForce "server";
    serverAddr = lib.mkForce "https://100.127.233.30:6443";
    tokenFile = lib.mkForce "/etc/k3s/token";
    extraFlags = lib.mkForce (toString [
      "--flannel-iface=tailscale0"
      "--node-label=topology.kubernetes.io/zone=eu-central"
      "--node-label=node.kubernetes.io/role=database"
      # RCA Aug 11 2026: k3s's own embedded containerd (image cache,
      # container state) lives under /var/lib/rancher/k3s by default,
      # on vega's 98G root disk -- the same root-disk-exhaustion class of
      # bug as the Docker data-root issue below, but for the runtime
      # that actually backs every running pod, not just manual `docker`
      # builds. Relocating to /data (1.65TB) for the same reason.
      "--data-dir=/data/k3s"
      # WS-5.4a (Aug 13 2026): proactive image GC so unpruned images get
      # cleaned at 70% disk usage instead of only at kubelet's default
      # hard-eviction threshold (85%) -- the original incident's images
      # only got collected AFTER DiskPressure had already evicted pods.
      # These are kubelet flags (valid on agents, unlike the earlier
      # --kube-controller-manager-arg attempt).
      "--kubelet-arg=image-gc-high-threshold=85"
      "--kubelet-arg=image-gc-low-threshold=80"
    ]);
  };

  # WS-5.4b (Aug 13 2026): Gitea 1.25.4 exposes no cleanup-rules API, so
  # image retention for the container registry is enforced here instead:
  # keep the newest 15 atlas-backend versions, delete the rest daily.
  # Token comes from /etc/gitea-prune.env (root:root 0600, created
  # manually -- NOT in the nix store, which is world-readable).
  systemd.services.gitea-registry-prune = {
    description = "Prune old atlas-backend images from Gitea registry (keep 15)";
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = "/etc/gitea-prune.env";
    };
    script = ''
      set -euo pipefail
      HOST="https://git.bernad.in"
      DOOMED=$(${pkgs.curl}/bin/curl -sf -H "Authorization: token $GITEA_TOKEN" \
        "$HOST/api/v1/packages/miguel?type=container&q=atlas-backend&limit=100" \
        | ${pkgs.jq}/bin/jq -r 'sort_by(.created_at) | reverse | .[15:] | .[].version')
      for V in $DOOMED; do
        echo "pruning atlas-backend:$V"
        ${pkgs.curl}/bin/curl -sf -X DELETE -H "Authorization: token $GITEA_TOKEN" \
          "$HOST/api/v1/packages/miguel/container/atlas-backend/$V" || echo "failed: $V"
      done
      echo "done; kept newest 15"
    '';
  };
  systemd.timers.gitea-registry-prune = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:30:00";
      Persistent = true;
    };
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

  # Docker image/layer storage relocated off the small root disk (98G)
  # onto /data (1.65TB, mounted separately for OpenEBS local volumes)
  # to prevent root-disk exhaustion during large image builds.
  # RCA Aug 11 2026: root filled to 98% during a calcom image build,
  # triggering DiskPressure evictions cluster-wide.
  virtualisation.docker.daemon.settings = {
    "data-root" = "/data/docker";
  };

  system.stateVersion = "25.11";
}
