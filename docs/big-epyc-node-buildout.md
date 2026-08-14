# Buildout spec: big Hetzner EPYC auction node (encrypted, remote-unlock)

Reusable procedure for provisioning a high-RAM Hetzner Auction EPYC box as a
k3s node with encryption at rest and remote SSH unlock. First built as
`rigel` (2026-08-13). Intended fleet end-state: two of these nodes
(`rigel` + one more, for redundancy) replacing `orion` and `vega`.

## When to use this

Hetzner Auction "value tier" win, EPYC 7002-series, large RAM (512GB+),
4x NVMe in two capacity classes (e.g. 2x3.84TB + 2x1.92TB). Adjust partition
sizes if the drive mix differs.

## Non-negotiable architecture rule

**`/boot` must be its own unencrypted partition, outside the LUKS container.**

Do NOT set `boot.loader.grub.enableCryptodisk = true` with `/boot` living
inside a LUKS volume. Confirmed via Hetzner vKVM console on rigel's first
build attempt: GRUB itself will block on a local-console LUKS passphrase
prompt before the kernel/initrd ever load. GRUB has no networking - remote
unlock is impossible in that layout, and the box goes totally silent on the
network after every reboot with no way to diagnose it except a live console.

The correct layout (see `hosts/rigel/disko.nix` as the reference):
- Small `EF02` BIOS-boot partition per disk (1M) - GRUB core.img embed area.
- Small mirrored **unencrypted** ext4 `/boot` (2G, RAID1 across both disks
  of the primary pair) - holds kernel + initrd, GRUB reads it directly.
- Remaining space -> RAID1 -> LUKS -> LVM (root + /data).
- Second disk pair -> RAID1 -> LUKS -> ext4 (secondary data volume).

With this layout, GRUB loads the kernel/initrd unencrypted, hands off to the
initrd, and the initrd is what owns the LUKS unlock over
`boot.initrd.network.ssh` - which is what actually enables remote unlock.

## Known gotchas (all hit building rigel, don't repeat them)

1. **NVMe device names (`/dev/nvmeXnY`) are not stable across boots** on
   this hardware - PCIe discovery order differs between the rescue
   environment and nixos-anywhere's own kexec'd installer. Always use
   `/dev/disk/by-id/nvme-<MODEL>_<SERIAL>` paths in `disko.nix`, confirmed
   via `ls -la /dev/disk/by-id/` on the SAME boot you're about to install
   from, not a prior session.
2. **`cryptsetup luksFormat` has no TTY during a scripted nixos-anywhere
   run.** Set `passwordFile` in each LUKS block in `disko.nix` to a local
   tmp path, and pass matching `--disk-encryption-keys <remote-path>
   <local-file>` (repeatable) to `nixos-anywhere`.
3. GRUB needs `boot.loader.grub.mirroredBoots` for redundant boot on both
   mirror members - disko wires this up automatically from the `EF02`
   partitions on both disks. Do NOT also manually set
   `boot.loader.grub.devices` - it duplicates disko's config and fails.
4. Confirm the actual NIC driver (`ethtool -i <iface>`) rather than
   guessing - add it to `boot.initrd.availableKernelModules`. Don't assume
   it matches a previous host's hardware generation.
5. Hetzner requires static IP - no DHCP. Set `boot.kernelParams` with the
   classic 7-field `ip=<client>::<gateway>:<netmask>::<device>:none` kernel
   parameter for the initrd's static networking (this is separate from the
   real system's `systemd.network` config, which only applies post-boot).
   This part alone is NOT sufficient without gotcha #1 above being fixed too.
6. Hetzner's rescue-mode Debian image ships an old mdadm/kernel combo that
   may fail with `does not have a valid v1.2 superblock, not importing!`
   /  `Invalid argument` when trying to assemble arrays created by a newer
   mdadm (e.g. from the nixos-anywhere install environment). This is a
   rescue-image tooling mismatch, not a sign of a real problem - don't
   chase it. If you need to inspect the real installed system's disk from
   rescue mode, read one RAID1 mirror member directly at its data offset
   (`losetup -o <data_offset*512> -r ...`) to bypass mdadm entirely,
   read-only.
7. If something is still wrong after a reinstall and you can't diagnose it
   from network silence alone, activate **vKVM** via the Robot web UI
   (Rescue tab -> OS dropdown -> "vkvm (Bookworm)" -> Activate -> reboot).
   It boots the real installed disk inside a VM wrapper and gives a live
   console over a web viewer / noVNC, at `https://<ip>:47773/`. This is
   how the /boot-inside-LUKS bug above was actually found - don't skip
   straight to guessing when this is available.

## Procedure

1. Confirm hardware via Hetzner Robot: `GET /server/<server-number>`.
   Register an SSH key for rescue access: `POST /key`. Activate rescue mode:
   `POST /boot/<server-number>/rescue` with `os=linux` and the key
   fingerprint. Hardware reset: `POST /reset/<server-number>` `type=hw`.
2. From rescue mode, confirm real by-id paths and NIC driver
   (`ls -la /dev/disk/by-id/`, `ethtool -i <iface>`).
3. Copy `hosts/rigel/{disko.nix,configuration.nix,hardware-configuration.nix}`
   to `hosts/<new-name>/`, updating: disk by-id serials, hostname, static IP
   (address/gateway), NIC interface name if different, k3s node-labels.
4. Generate a dedicated initrd SSH host key (`ssh-keygen -t ed25519 -N ""`)
   and stage it plus the k3s join token under an `--extra-files` directory
   matching `etc/secrets/initrd/` and `etc/k3s/token`.
5. Generate LUKS passphrases (`openssl rand -base64 32`, one per encrypted
   array) and stage as local key files referenced by `disko.nix`'s
   `passwordFile` fields.
6. Add the new host to `flake.nix` `nixosConfigurations` (mirror rigel's
   entry, including disko module).
7. `nix flake check` / eval the toplevel drv as a sanity check before
   deploying.
8. Run `nixos-anywhere --flake .#<new-name> --extra-files <dir>
   --disk-encryption-keys <remote> <local> [...] root@<ip>`.
9. After reboot, confirm the initrd SSH server answers within ~2 minutes
   (not 10+ - if it's not reachable quickly, something regressed on gotcha
   #1 above; go to vKVM before assuming it's just slow POST).
10. Unlock: `ssh -i <portable key> root@<ip>`, then run `cryptsetup-askpass`
    per encrypted array (accept the host-key-changed warning - the initrd
    uses its own dedicated host key, different from the real system's).
11. Once the real system is up: place the shared Tailscale authkey (k8s
    secret `tailscale-authkey` in `kube-system` or `kube-autoscaler`,
    identical in both) at `/etc/tailscale/authkey`, restart
    `tailscale-autoconnect.service`, then restart `k3s` so it can join over
    `tailscale0`.
12. Store the portable unlock private key, both LUKS passphrases, and the
    step-by-step recovery process in Proton Pass as one item (see
    `rigel`'s "Rigel - LUKS Unlock SSH Key" entry in the Personal vault for
    the exact format - key fields + numbered recovery-steps fields).
13. Commit and push the new host's files once the install is verified
    working end-to-end (booted, unlocked, joined the cluster).

## Fleet consolidation context

Plan (as of 2026-08-13): acquire one more similarly-specced node for
redundancy, then decommission `orion` (current k3s control-plane) and
`vega`, converging onto `rigel` + the new node. Revisit control-plane HA at
that point - two big nodes is also the right moment to make the control
plane itself redundant instead of just moving the single-point-of-failure
to a bigger box.
