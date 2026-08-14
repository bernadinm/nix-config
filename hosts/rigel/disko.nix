# Rigel EPYC 7502P Disk Configuration (for nixos-anywhere)
# 1TB RAM node, 4x NVMe in two mirrored pairs, both encrypted at rest (LUKS).
#
# IMPORTANT: uses /dev/disk/by-id paths, not /dev/nvmeXnY. NVMe device
# names are assigned in PCIe discovery order at boot and are NOT stable
# across boots on this hardware - confirmed the hard way when nixos-anywhere's
# kexec'd installer enumerated the same physical drives under different
# nvmeXnY names than the initial rescue boot, silently pairing a 3.84TB
# drive with a 1.92TB drive under the old by-name config.
#
# IMPORTANT: /boot is its own unencrypted mirrored ext4 partition, NOT inside
# the LUKS container. Confirmed via Hetzner vKVM console that with /boot
# inside LUKS + grub.enableCryptodisk, GRUB itself blocks on a local-console
# passphrase prompt before the kernel/initrd ever load - defeating remote
# unlock entirely, since GRUB has no networking. The initrd (loaded from this
# unencrypted /boot) is what must own the LUKS unlock, via boot.initrd.network.ssh.
#
# Layout:
#   2x SAMSUNG MZQL23T8HCLS (3.84TB) -> mdadm RAID1 "bootraid" -> ext4 /boot (2G, unencrypted)
#                                     -> mdadm RAID1 "main"     -> LUKS "cryptmain" -> LVM VG "pool"
#     LV "root": 150G for NixOS
#     LV "data": ~3.3T for /data (primary - the eventual migration target)
#   2x SAMSUNG MZQLB1T9HAJR (1.92TB) -> mdadm RAID1 "secondary" -> LUKS "cryptsecondary" -> ext4 /data2
# Root is unlocked remotely at boot via boot.initrd.network.ssh (see configuration.nix).
{ lib, ... }:

{
  disko.devices = {
    disk = {
      main1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNE0R602493";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            bootfs = {
              size = "2G";
              content = {
                type = "mdraid";
                name = "bootraid";
              };
            };
            main = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "main";
              };
            };
          };
        };
      };
      main2 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZQL23T8HCLS-00A07_S64HNE0T222096";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            bootfs = {
              size = "2G";
              content = {
                type = "mdraid";
                name = "bootraid";
              };
            };
            main = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "main";
              };
            };
          };
        };
      };
      secondary1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZQLB1T9HAJR-00007_S439NA0R105356";
        content = {
          type = "gpt";
          partitions = {
            secondary = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "secondary";
              };
            };
          };
        };
      };
      secondary2 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-SAMSUNG_MZQLB1T9HAJR-00007_S439NA0R200594";
        content = {
          type = "gpt";
          partitions = {
            secondary = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "secondary";
              };
            };
          };
        };
      };
    };

    mdadm = {
      bootraid = {
        type = "mdadm";
        level = 1;
        content = {
          type = "filesystem";
          format = "ext4";
          mountpoint = "/boot";
        };
      };
      main = {
        type = "mdadm";
        level = 1;
        content = {
          type = "luks";
          name = "cryptmain";
          # Populated by `nixos-anywhere --disk-encryption-keys` before install
          # runs, so luksFormat doesn't block on an interactive prompt with no
          # TTY. Not used after install - unlocking then happens interactively
          # via the initrd SSH server (see configuration.nix).
          passwordFile = "/tmp/cryptmain.key";
          settings.allowDiscards = true;
          content = {
            type = "lvm_pv";
            vg = "pool";
          };
        };
      };
      secondary = {
        type = "mdadm";
        level = 1;
        content = {
          type = "luks";
          name = "cryptsecondary";
          passwordFile = "/tmp/cryptsecondary.key";
          settings.allowDiscards = true;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/data2";
            mountOptions = [ "noatime" "nodiratime" ];
          };
        };
      };
    };

    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "150G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
          data = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/data";
              mountOptions = [ "noatime" "nodiratime" ];
            };
          };
        };
      };
    };
  };
}
