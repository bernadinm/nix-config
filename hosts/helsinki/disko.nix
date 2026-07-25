# Helsinki AX41 Disk Configuration (for nixos-anywhere)
# Dedicated server with 2x NVMe drives
# nvme0n1: OS (boot + root)
# nvme1n1: Data partition for TimescaleDB
{ lib, ... }:

{
  disko.devices = {
    disk = {
      os = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";  # BIOS boot partition for GRUB on GPT
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      data = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            data = {
              size = "100%";
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
  };
}
