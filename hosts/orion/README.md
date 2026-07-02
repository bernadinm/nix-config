# Orion - Remote k3s Worker Node

Remote VPS running as a k3s agent, joining astra's cluster via Tailscale.

## Specs
- **CPU**: AMD EPYC (4 vCPU)
- **RAM**: 8 GB
- **Disk**: 160 GB SSD
- **Location**: US East

## Initial Installation

Orion was installed using [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) which allows remote NixOS installation over SSH.

### Prerequisites
1. VPS provisioned with any Linux (Ubuntu, Debian, etc.)
2. SSH access as root
3. nixos-anywhere available: `nix-shell -p nixos-anywhere`

### Install Command
```bash
cd ~/git/bernadinm/nix-config
nixos-anywhere --flake .#orion root@<IP_ADDRESS>
```

This will:
1. Boot into a kexec NixOS installer environment
2. Partition the disk using disko configuration
3. Install NixOS with the orion configuration
4. Reboot into the new system

### Post-Install Setup

1. **Authenticate Tailscale**:
   ```bash
   ssh miguel@<IP_ADDRESS>
   sudo tailscale up --ssh
   # Visit the URL to authenticate
   ```

2. **Create k3s token file** (get token from astra):
   ```bash
   ssh astra "sudo cat /var/lib/rancher/k3s/server/node-token"

   ssh miguel@orion
   sudo mkdir -p /var/lib/rancher/k3s/server
   echo '<TOKEN>' | sudo tee /var/lib/rancher/k3s/server/agent-token
   sudo chmod 600 /var/lib/rancher/k3s/server/agent-token
   ```

3. **Rebuild to start k3s agent**:
   ```bash
   cd ~/git/bernadinm/nix-config
   sudo nixos-rebuild switch --flake .#orion
   ```

4. **Label as worker** (from astra):
   ```bash
   kubectl label node orion node-role.kubernetes.io/worker=true
   ```

## Updating

For regular updates, use standard nixos-rebuild:
```bash
ssh miguel@orion
cd ~/git/bernadinm/nix-config
git pull
sudo nixos-rebuild switch --flake .#orion
```

## Notes

- Uses GRUB legacy BIOS boot (cloud VMs don't support UEFI)
- Firewall only exposes SSH (port 22) on public interface
- All k8s traffic flows through Tailscale (trustedInterfaces)
- Provisioned via Crossplane in homelab repo
