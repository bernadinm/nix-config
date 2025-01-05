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
  boot.kernelParams = [
    # "intel_pstate=disable"  # Be cautious; test for stability
    "pcie_aspm=force"
  ];
  boot.kernelModules = [ "kvm-intel" "hid-apple" "ashmem_linux" "binder_linux" ];
  #  See: https://community.frame.work/t/resolved-fn-lock-makes-both-fn-f-and-f-trigger-the-media-control-keys/26282/16
  boot.blacklistedKernelModules = [ "cros_ec_lpcs" ]; # fn + ctrl fw linux bug
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
    [{ device = "/dev/disk/by-uuid/9601ad7a-71f7-48e6-98af-ce5aa44a773e"; }];

  environment.systemPackages = with pkgs; [
    auto-cpufreq
  ];

  services.auto-cpufreq.enable = true;
}
