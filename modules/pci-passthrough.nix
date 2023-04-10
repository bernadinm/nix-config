# put this file in /etc/nixos/
# change the settings tagged with "CHANGE:"
# and add 
#   ./pci-passthrough.nix
# to /etc/nixos/configuration.nix in `imports`

{ config, pkgs, ... }:
{
  # CHANGE: intel_iommu enables iommu for intel CPUs with VT-d
  # use amd_iommu if you have an AMD CPU with AMD-Vi

  #boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelParams = [ "amd_iommu=on" "vfio-pci.ids=10de:2204,10de:1aef" ];

  boot.loader = {
    # Use the systemd-boot EFI boot loader.
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot.kernelParams = [ "amd_iommu=on" ];

  # These modules are required for PCI passthrough, and must come before early modesetting stuff
  boot.kernelModules = [ "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" "pcie_aspm=off" ];
  boot.initrd.availableKernelModules = [ "vfio-pci" ];
  #boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # CHANGE: Don't forget to put your own PCI IDs here
  #boot.extraModprobeConfig = "options vfio-pci ids=10de:2204,10de:1aef";

  environment.systemPackages = with pkgs; [
    virtmanager
    qemu
    OVMF
  ];

  # virtualisation.libvirtd.enableKVM = true;
  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
    onBoot = "ignore";
    onShutdown = "shutdown";
    qemu.package = pkgs.qemu_kvm;
  };


  # CHANGE: add your own user here
  users.groups.libvirtd.members = [ "root" "miguel" ];
  users.groups.qemu-libvirtd.members = [ "root" "miguel" ];

  virtualisation.spiceUSBRedirection.enable = true;
  hardware.opengl.enable = true;


  # CHANGE: use 
  #     ls /nix/store/*OVMF*/FV/OVMF{,_VARS}.fd | tail -n2 | tr '\n' : | sed -e 's/:$//'
  # to find your nix store paths
  # virtualisation.libvirtd.qemu.verbatimConfig = ''
  #   nvram = [
  #     "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd"
  #   ]
  # '';

  #boot.postBootCommands = ''
  #    DEVS="0000:09:00.0 0000:09:00.1"
  #    for DEV in $DEVS; do
  #      echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  #    done
  #    modprobe -i vfio-pci
  #  '';

  #boot.initrd.preDeviceCommands = ''
  #  DEVS="0000:09:00.0 0000:09:00.1"
  #  for DEV in $DEVS; do
  #    echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  #  done
  #  modprobe -i vfio-pci
  #'';
}
