# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" "hid-apple" "ashmem_linux" "binder_linux" ];
  boot.extraModulePackages = [ ];
  boot.extraModprobeConfig = ''
      options hid_apple fnmode=2
  '';

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/b65f0c6a-b50c-4ba7-9a91-fcb5a831f65e";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/1114-0DFA";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/66860ab1-4fa8-40e0-8bdc-cbd2ca3a3be8"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
