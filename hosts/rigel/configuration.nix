# Rigel - Highest-Memory Compute Node (eventual primary migration target)
# Purpose: 1TB RAM, k3s agent, encrypted at rest, unlocked remotely via SSH at boot
# Hardware: Hetzner Auction - AMD EPYC 7502P, 1024GB RAM, 2x3.5TB + 2x1.7TB NVMe (mirrored)
# Location: Germany, FSN1-DC18
# Named for the brightest star in Orion - intended successor role to the orion host.
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

  # GRUB on both mirror members - either disk can boot if the other fails.
  # disko.nix declares EF02 boot partitions on both nvme0 and nvme3, which
  # wires up boot.loader.grub.mirroredBoots automatically - don't also set
  # grub.devices manually here, it duplicates disko's own config.
  boot.loader.grub.enable = true;
  # /boot is its own unencrypted mirrored ext4 partition (see disko.nix) -
  # GRUB never touches the LUKS layer, so no enableCryptodisk here. Confirmed
  # via vKVM that enableCryptodisk + /boot-inside-LUKS makes GRUB itself block
  # on a local passphrase prompt before the kernel/initrd load, which defeats
  # remote unlock entirely since GRUB has no networking. The initrd (now
  # loadable without unlocking anything) is what owns the LUKS unlock, over
  # boot.initrd.network.ssh below.
  boot.loader.grub.configurationLimit = 10;

  networking.hostName = "rigel";

  # Static IP via systemd-networkd, same pattern as vega (same NIC/interface
  # naming, enp195s0, on this Hetzner hardware generation).
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network = {
    enable = true;
    networks."10-wan" = {
      matchConfig.Name = "enp195s0";
      networkConfig = {
        DHCP = "no";
        IPv6AcceptRA = "no";
      };
      addresses = [
        { Address = "162.55.93.233/26"; }
      ];
      routes = [
        { Gateway = "162.55.93.193"; }
      ];
      linkConfig.RequiredForOnline = "routable";
    };
    networks."99-veth-ignore" = {
      matchConfig.Name = "veth*";
      linkConfig.Unmanaged = "yes";
    };
    networks."99-cni-ignore" = {
      matchConfig.Name = "cni*";
      linkConfig.Unmanaged = "yes";
    };
    networks."99-flannel-ignore" = {
      matchConfig.Name = "flannel*";
      linkConfig.Unmanaged = "yes";
    };
  };

  networking.nameservers = [ "185.12.64.1" "185.12.64.2" "1.1.1.1" ];
  services.resolved = {
    enable = true;
    fallbackDns = [ "185.12.64.1" "1.1.1.1" "8.8.8.8" ];
  };
  services.tailscale.extraUpFlags = [ "--accept-dns=false" ];

  time.timeZone = "Europe/Berlin";
  system.autoUpgrade.enable = lib.mkForce false;

  systemd.settings.Manager = {
    RuntimeWatchdogSec = "90s";
    RebootWatchdogSec = "120s";
  };

  services.openssh.listenAddresses = [
    { addr = "0.0.0.0"; port = 22; }
  ];

  systemd.services.tailscaled.serviceConfig = {
    Restart = lib.mkForce "always";
    RestartSec = 5;
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "docker-28.5.2" "electron-39.8.10" ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # === Encryption at rest ===
  # Both mdadm RAID1 arrays are LUKS-encrypted. Root (LV "root" on array
  # "main") must be unlocked before the real system boots, which needs a
  # passphrase entered remotely since there's no physical console.
  # boot.initrd.network brings up networking early with the same static
  # config as the real system, then boot.initrd.network.ssh runs a minimal
  # sshd so `ssh root@<ip>` at boot drops you into initrd to unlock it.
  boot.initrd.availableKernelModules = [ "igb" ];
  # boot.initrd.network defaults to DHCP - Hetzner requires static, so the
  # initrd stage needs its own explicit static config via the kernel `ip=`
  # parameter (separate from systemd.network above, which only configures
  # the real, post-boot system).
  boot.kernelParams = [
    "ip=162.55.93.233::162.55.93.193:255.255.255.192::enp195s0:none"
  ];
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 22;
      # Dedicated key, NOT the real host's key - generated once and injected
      # via `nixos-anywhere --extra-files` since it must exist outside the
      # encrypted disk (initrd can't read /etc/ssh before root is unlocked).
      hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN0CfdoI+UbPdWWHpeo3OPy3T1AtnOEs2k6wjH6o9OoV miguel@vega"
        # Portable unlock key, not hardware-bound - private half stored in
        # Proton Pass so it can be used from any machine (not YubiKey-gated).
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtgYNqUQMXZntFraIjXgJAqRnkBRm+dApZ9ZLFUv6B2 rigel-luks-unlock-portable"
      ];
    };
    # cryptsetup's askpass hooks stdin automatically on ssh login to the
    # initrd shell - typing the passphrase there unlocks the LUKS devices
    # and the boot continues.
  };
  boot.initrd.luks.devices = {
    cryptmain = {
      device = "/dev/md/main";
      allowDiscards = true;
    };
    cryptsecondary = {
      device = "/dev/md/secondary";
      allowDiscards = true;
    };
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2026-08.nixos:rigel";
  };
  boot.kernelModules = [ "iscsi_tcp" "nvme_tcp" ];

  # OpenEBS Mayastor storage node: io-engine needs 2MiB hugepages (2GiB
  # reserved) and NVMe-over-TCP for replication transport.
  boot.kernel.sysctl."vm.nr_hugepages" = 1024;
  # Mayastor DiskPool backing file lives on the big encrypted /data volume;
  # the io-engine container only sees /var/local/mayastor/io-engine, so bind
  # the real location there. Pool disk URI uses ?blk_size=4096 (LUKS stack
  # exposes 4K sectors).
  fileSystems."/var/local/mayastor/io-engine" = {
    device = "/data/mayastor";
    options = [ "bind" ];
  };
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/iscsiadm - - - - /run/current-system/sw/bin/iscsiadm"
    "L+ /usr/bin/mount - - - - /run/current-system/sw/bin/mount"
    "L+ /usr/bin/umount - - - - /run/current-system/sw/bin/umount"
    "L+ /usr/bin/nsenter - - - - /run/current-system/sw/bin/nsenter"
  ];

  environment.systemPackages = with pkgs; [
    htop btop ncdu tmux vim neovim git curl wget rsync tree
  ];

  networking.firewall.checkReversePath = "loose";
  services.tailscale.useRoutingFeatures = "both";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" "cni0" ];
  };

  services.openssh.settings = {
    PasswordAuthentication = lib.mkForce false;
    PermitRootLogin = lib.mkForce "no";
    KbdInteractiveAuthentication = false;
  };

  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  nix.settings.trusted-users = [ "root" "miguel" ];

  # 2026-08-19: promoted from agent to server (control-plane + etcd member)
  # - third and final step of converting to a real 3-node HA control plane
  # (orion + vega + rigel), now that orion's datastore is etcd. Join
  # mechanics unchanged, same rationale as vega's identical promotion.
  services.k3s = {
    role = lib.mkForce "server";
    serverAddr = lib.mkForce "https://100.127.233.30:6443";
    tokenFile = lib.mkForce "/etc/k3s/token";
    extraFlags = lib.mkForce (toString [
      "--flannel-iface=tailscale0"
      "--node-label=topology.kubernetes.io/zone=eu-central"
      "--node-label=node.kubernetes.io/role=high-memory"
      "--data-dir=/data/k3s"
    ]);
  };

  systemd.services.k3s = {
    after = [ "tailscale-autoconnect.service" ];
    wants = [ "tailscale-autoconnect.service" ];
  };

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
        ${pkgs.tailscale}/bin/tailscale up --authkey "$(cat /etc/tailscale/authkey)" --accept-dns=false
        echo "Tailscale connected with auth key"
      else
        echo "No auth key found at /etc/tailscale/authkey - manual connection required"
      fi
    '';
  };

  virtualisation.docker.daemon.settings = {
    "data-root" = "/data/docker";
  };

  system.stateVersion = "25.11";
}
