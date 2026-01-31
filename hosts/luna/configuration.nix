# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/gdrivesync.nix
      ../../modules/entertainment.nix
      ../../modules/security.nix
      ../../modules/virtualization.nix
      ../../modules/communication.nix
      ../../modules/monitoring.nix
      ../../modules/desktop.nix
      ../../modules/utilities.nix
      ../../modules/coding.nix
      ../../modules/timemachinebackup.nix
      # TODO(bernadinm): Replace Mesh Network for Zero Trust
      # <nixos-unstable/nixos/modules/services/networking/nebula.nix>
    ];
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Luna"; # Define your hostname.
  networking.networkmanager.enable = true; # Use networkmanager for wifi

  # Set your time zone.
  time.timeZone = "Africa/Nairobi";
  #time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.wlp1s0.useDHCP = true;

  # bernadinm(todo): remove me
  # networking.extraHosts =
  #   ''
  #     192.168.100.2 lumina
  #   '';

  boot.kernelPackages = pkgs.linuxPackages_latest; #- for WiFi support
  
  # Power management kernel parameters
  boot.kernelParams = [
    "pcie_aspm=force"
    "iwlwifi.power_save=1"
    "ahci.mobile_lpm_policy=3"
    "mem_sleep_default=deep"
  ];

  nixpkgs.config.allowUnfree = true;

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw
  # Enable the X11 windowing system.

  # Required for Framework Laptop to help avoid screen tearing:
  # https://discourse.nixos.org/t/eliminate-screen-tearing-with-intel-mesa/14724
  services.xserver.videoDrivers = [ "modesetting" ];
  services.xserver.deviceSection = ''
    Option "DRI" "2"
    Option "TearFree" "true"
  '';

  home-manager.users.miguel.home.file =
    {
      ".config/hypr/hyprland.conf".source =
        .config/hypr/hyprland.conf;
      ".config/libinput-gestures.conf".source =
        .config/libinput-gestures.conf;
    };

  home-manager.users.rachelle.home.file =
    {
      ".config/hypr/hyprland.conf".source =
        .config/hypr/hyprland.conf;
      ".config/libinput-gestures.conf".source =
        .config/libinput-gestures.conf;
    };

  services.upower.enable = true;
  services.auto-cpufreq.enable = true;
  services.xserver = {
    # small addition from desktop.nix import
    monitorSection = ''
      DisplaySize 408 306
    '';
  };

  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/508642b3-eced-4e85-9c67-e6e85d946d96";
  boot.initrd.luks.devices.root.preLVM = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplip pkgs.canon-cups-ufr2 pkgs.epsonscan2 ];

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.touchpad.naturalScrolling = true;
  services.libinput.touchpad.disableWhileTyping = true;
  services.libinput.mouse.disableWhileTyping = true;
  services.xserver.xkb.options = "ctrl:swap_lfctl_lfwin"; # swap ctrl + fn keys

  #hardware.trackpoint.programs.light.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  # Installing TLP for Battery Life Optimization
  # services.tlp.enable = true;

  # hybrid sleep when press power button
  services.logind.extraConfig = ''
    HandlePowerKeyLongPress=poweroff
    HandlePowerKey=suspend-then-hibernate
    HandleLidSwitch=hibernate
    HandleLidSwitchExternalPower=hibernate
    HandleLidSwitchDocked=ignore
    IdleAction=hibernate
    IdleActionSec=15min
  '';
  # screen locker
  programs.xss-lock.enable = true;
  programs.xss-lock.lockerCommand = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 15 30";

  # Enable display manager to use Hyprland session
  services.displayManager.sessionPackages = with pkgs; [ hyprland ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ddcutil
    i2c-tools
    libinput-gestures
    pulseeffects-legacy
    
    # Power management tools
    powertop          # Power usage analyzer and tuner
    acpi              # ACPI utilities
    lm_sensors        # Hardware monitoring
    # turbostat         # CPU power analysis
    
    # Bluetooth toggle script (Shift+F10)
    (pkgs.writeScriptBin "bt-toggle" ''
      #!/bin/bash
      if lsmod | grep -q btusb; then
        echo "Disabling Bluetooth to save power..."
        sudo modprobe -r btusb
        notify-send "Bluetooth Disabled" "Hardware powered off for battery savings"
      else
        echo "Enabling Bluetooth..."
        sudo modprobe btusb
        sleep 2
        sudo systemctl restart bluetooth
        notify-send "Bluetooth Enabled" "Hardware powered on and ready"
      fi
    '')
    
    # Hyprland and related packages
    hyprland
    waybar
    wofi
    swaybg
    swayidle
    swaylock-effects
  ];

  # Monitor Control via CLI
  services.ddccontrol.enable = true;
  hardware.i2c.enable = true;

  # Enable Nebula Mesh Network
  # TODO(bernadinm): Replace Mesh Network for Zero Trust
  # services.nebula.networks.mesh = {
  #   staticHostMap = { "192.168.100.2" = [ "lumina.miguel.engineer:4242" ]; };
  # };

  services.fwupd.enable = true; # firmware update tool
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xautolock.fprintAuth = true;
  
  # Power optimization settings
  # Disable touchegg service that was consuming 397mW + causing AMD interrupts
  services.touchegg.enable = false;
  
  # PowerTOP automatic tuning service
  systemd.services.powertop-autotune = {
    enable = true;
    description = "PowerTOP Auto Tune on Boot";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.powertop}/bin/powertop --auto-tune";
    };
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
  };
  
  # Sudoers rules for Bluetooth toggle (no password required)
  security.sudo.extraRules = [
    {
      users = [ "miguel" ];
      commands = [
        {
          command = "${pkgs.kmod}/bin/modprobe btusb";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.kmod}/bin/modprobe -r btusb";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.systemd}/bin/systemctl restart bluetooth";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  
  # Bluetooth optimization - power efficient
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;  # Don't power on at boot - use Shift+F10 toggle
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = false;
        FastConnectable = false;  # Disable for power savings
        AutoConnect = false;      # Manual connection only
      };
      Policy = {
        AutoEnable = false;
        IdleTimeout = 30;
      };
    };
  };
  
  # Power management via udev rules
  services.udev.extraRules = ''
    # Enable power management for all PCI devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    # USB autosuspend
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    # Network interface power management
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save on"
  '';

  # TODO(bernadinm): required for home manager 23.05
  nixpkgs.config.permittedInsecurePackages = [
    "electron-27.3.11" # used for logseq and obsidian
    "ventoy-1.1.05"
    "python3.12-ecdsa-0.19.1"
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
