# Vega EPYC 7502P Disk Configuration (for nixos-anywhere)
# 2x 894GB NVMe combined via LVM for ~1.7TB unified storage
# Layout:
#   nvme0n1: 1M BIOS boot + LVM PV
#   nvme1n1: LVM PV
#   VG "pool": spans both drives
#     LV "root": 100GB for NixOS
#     LV "data": ~1.6TB for /data (TimescaleDB, k8s PVs)
{ lib, ... }:

{
  disko.devices = {
    disk = {
      nvme0 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            primary = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
      nvme1 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            primary = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      pool = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100G";
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
