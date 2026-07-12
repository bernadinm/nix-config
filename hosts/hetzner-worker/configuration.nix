# Hetzner Worker - Dynamic k3s Agent Node
# Purpose: Auto-scaled worker node that joins the Orion k3s cluster via Tailscale
#
# This config is used as a template for dynamically provisioned Hetzner VMs.
# The hostname, Tailscale auth key, and k3s token are injected at deploy time.
#
# Provisioning flow:
#   1. Crossplane creates Hetzner server with Ubuntu
#   2. nixos-anywhere installs NixOS from this config
#   3. Tailscale connects to mesh network
#   4. k3s agent joins Orion cluster
#   5. Node is ready for pod scheduling
#
{ config, pkgs, lib, ... }:

{
  imports = [
    ../../modules/server.nix
  ];

  # GRUB for legacy BIOS boot (Hetzner cloud VMs)
  boot.loader.grub.enable = true;

  # Hostname is set dynamically via nixos-anywhere --extra-files
  # Default for template purposes
  networking.hostName = lib.mkDefault "hetzner-worker";

  # DHCP for public IP from Hetzner
  networking.useDHCP = true;

  time.timeZone = "America/New_York";

  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Minimal packages for a worker node
  environment.systemPackages = with pkgs; [
    htop
    vim
    curl
    git
  ];

  # Strict firewall — only SSH exposed, k8s traffic via Tailscale
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" "cni0" ];
  };

  # SSH hardening
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

  # Tailscale — auth key is provisioned to /etc/tailscale/authkey at deploy time
  services.tailscale.enable = true;

  # Auto-authenticate Tailscale on first boot using provisioned auth key
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
      # Wait for tailscaled to be ready
      sleep 5

      # Check if already connected
      status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState // "Unknown"')
      if [ "$status" = "Running" ]; then
        echo "Tailscale already connected"
        exit 0
      fi

      # Read auth key from provisioned file
      if [ -f /etc/tailscale/authkey ]; then
        ${pkgs.tailscale}/bin/tailscale up --authkey="$(cat /etc/tailscale/authkey)" --ssh --accept-routes
        echo "Tailscale connected with auth key"
      else
        echo "No auth key found at /etc/tailscale/authkey — manual connection required"
      fi
    '';
  };

  # k3s agent — joins Orion control plane via Tailscale
  services.k3s = {
    role = lib.mkForce "agent";
    serverAddr = lib.mkForce "https://100.127.233.30:6443";  # Orion via Tailscale
    tokenFile = lib.mkForce "/etc/k3s/token";
    extraFlags = lib.mkForce (toString [
      "--flannel-iface=tailscale0"
      "--node-label=topology.kubernetes.io/zone=hetzner"
      "--node-label=node.kubernetes.io/lifecycle=spot"
    ]);
  };

  # k3s depends on Tailscale being connected
  systemd.services.k3s = {
    after = [ "tailscale-autoconnect.service" ];
    wants = [ "tailscale-autoconnect.service" ];
  };

  # Auto-cleanup: if this node is drained and idle for 10 minutes, shut down
  # The Crossplane controller will detect the shutdown and delete the server
  systemd.services.auto-shutdown-idle = {
    description = "Shutdown if node is drained and idle";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      # Check if node is cordoned (unschedulable)
      NODE_NAME=$(hostname)
      UNSCHEDULABLE=$(${pkgs.kubectl}/bin/kubectl get node "$NODE_NAME" -o jsonpath='{.spec.unschedulable}' --kubeconfig=/etc/rancher/k3s/agent/kubelet.kubeconfig 2>/dev/null || echo "false")

      if [ "$UNSCHEDULABLE" = "true" ]; then
        # Check if no pods are running (except daemonsets)
        POD_COUNT=$(${pkgs.kubectl}/bin/kubectl get pods --field-selector=spec.nodeName="$NODE_NAME" --all-namespaces --no-headers 2>/dev/null | wc -l)
        if [ "$POD_COUNT" -le 2 ]; then
          echo "Node is cordoned with $POD_COUNT pods — shutting down"
          ${pkgs.systemd}/bin/systemctl poweroff
        fi
      fi
    '';
  };

  systemd.timers.auto-shutdown-idle = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/10";  # Check every 10 minutes
      Persistent = true;
    };
  };

  system.stateVersion = "25.11";
}
