{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # fileSystems.* is generated automatically by disko.nix - do not duplicate here.

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "igb" "raid1" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # mdadm RAID1 arrays need auto-assembly support at boot.
  boot.swraid.enable = true;

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
