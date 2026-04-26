{ config, pkgs, lib, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/dotfiles.nix
      ../../modules/gdrivesync.nix
      ../../modules/entertainment.nix
      ../../modules/security.nix
      ../../modules/virtualization.nix
      ../../modules/communication.nix
      ../../modules/monitoring.nix
      ../../modules/desktop.nix
      ../../modules/utilities.nix
      ../../modules/coding.nix
      ../../modules/backups.nix
      ../../modules/server.nix  # Add server capabilities (k3s + GitHub Actions runner)
      # home-manager is now provided by flake.nix
    ];

  # Override server.nix settings - Luna is a desktop+server hybrid
  services.xserver.enable = lib.mkForce true;
  nix.gc.options = lib.mkForce "--delete-older-than 60d";  # Use desktop's longer retention

  # Re-enable suspend for laptop (server.nix disables all sleep)
  systemd.targets.sleep.enable = lib.mkForce true;
  systemd.targets.suspend.enable = lib.mkForce true;
  systemd.targets.hibernate.enable = lib.mkForce true;

  # AMD-specific sleep configuration for modern standby (s2idle)
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=yes
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
    SuspendState=freeze
  '';

  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "Luna"; # Define your hostname.

  networking.networkmanager.enable = true; # Use networkmanager for wifi

  # Fix Tailscale MagicDNS on NixOS with NetworkManager
  # Without this, Tailscale DNS (100.100.100.100) has no upstream resolvers
  networking.resolvconf.useLocalResolver = false;

  # Enable systemd-resolved to fix DNS race condition at boot and after sleep
  # This resolves conflicts between Tailscale DNS, NetworkManager, and system DNS
  services.resolved.enable = true;

  # Set your time zone.
  time.timeZone = "Africa/Nairobi";
  #time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Using NetworkManager for WiFi, so disable per-interface dhcpcd to avoid conflicts
  networking.useDHCP = false;

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
    "mem_sleep_default=s2idle"  # Use s2idle (modern standby) instead of deep - hardware doesn't support S3
    "usbcore.autosuspend=-1"    # Disable USB autosuspend to prevent wake issues
    "ucsi_acpi.dyndbg=+p"       # Enable debug logging for UCSI ACPI
    "resume=/dev/disk/by-uuid/9601ad7a-71f7-48e6-98af-ce5aa44a773e"  # Enable hibernation to swap
  ];

  # Workaround for Framework AMD USB-C ACPI wake issues
  # The ucsi_acpi module has firmware bugs causing spurious wake events
  boot.blacklistedKernelModules = [ "ucsi_acpi" ];

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

  # Home Manager - backup existing files
  home-manager.backupFileExtension = "backup";

  # Desktop-specific home-manager settings (base config in dotfiles.nix)
  home-manager.users.miguel = { pkgs, ... }: {
    home.file = {
      ".config/hypr/hyprland.conf".source = .config/hypr/hyprland.conf;
      ".config/hypr/hypridle.conf".source = .config/hypr/hypridle.conf;
      ".config/libinput-gestures.conf".source = .config/libinput-gestures.conf;
      ".config/waybar/config".source = ./.config/waybar/config;
      ".config/waybar/style.css".source = ./.config/waybar/style.css;
    };
    programs.waybar.enable = true;

    # Override pinentry for desktop (rofi instead of curses)
    services.gpg-agent.pinentry.package = pkgs.pinentry-rofi;

    # Cursor theme
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    # GTK theme - Catppuccin Mocha (Dark)
    gtk = {
      enable = true;
      theme = {
        name = "Catppuccin-Mocha-Standard-Mauve-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "mauve" ];
          size = "standard";
          variant = "mocha";
        };
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    # Qt theme - force dark
    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style.name = "adwaita-dark";
    };

    # Dark mode for all applications
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "Catppuccin-Mocha-Standard-Mauve-Dark";
      };
    };

    # Gammastep for screen color temperature (Wayland alternative to Redshift)
    services.gammastep = {
      enable = true;
      provider = "manual";
      latitude = 37.773972;  # San Francisco
      longitude = -122.431297;
      temperature = {
        day = 5500;
        night = 3200;
      };
    };
  };

  home-manager.users.rachelle.home.file =
    {
      ".config/hypr/hyprland.conf".source =
        .config/hypr/hyprland.conf;
      ".config/libinput-gestures.conf".source =
        .config/libinput-gestures.conf;
    };

  # Power management - UPower for battery monitoring and low battery actions
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 10;
    percentageAction = 5;
    criticalPowerAction = "PowerOff";
  };
  services.auto-cpufreq.enable = true;
  services.xserver = {
    # small addition from desktop.nix import
    monitorSection = ''
      DisplaySize 408 306
    '';
  };

  boot.initrd.luks.devices.root.device = "/dev/disk/by-uuid/508642b3-eced-4e85-9c67-e6e85d946d96";
  boot.initrd.luks.devices.root.preLVM = true;

  # Suspend support (hibernate disabled by server.nix)

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
  services.logind.settings.Login = {
    HandlePowerKeyLongPress = "poweroff";
    HandlePowerKey = "suspend";
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";  # Hypridle handles auto-suspend, not logind
    IdleActionSec = "30min";
  };
  # screen locker (Wayland)
  # Note: xss-lock is X11-only. For Wayland, use swayidle with swaylock
  # programs.xss-lock.enable = false;
  # Configure swaylock via swayidle in your Hyprland config

  # Enable Hyprland as a Wayland compositor
  programs.hyprland.enable = true;

  # Configure XDG Desktop Portal for Hyprland (required for screen sharing and input injection)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    config.common.default = "*";
  };

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
     (pkgs.writeScriptBin "bt-toggle" (builtins.readFile ./bt-toggle.sh))
    
    # Hyprland and related packages
    hyprland
    waybar
    wofi
    swaybg
    hypridle
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
  security.pam.services.login.fprintAuth = pkgs.lib.mkForce true;
  security.pam.services.xautolock.fprintAuth = true;
  
  # Power optimization settings
  # Disable touchegg service that was consuming 397mW + causing AMD interrupts
  services.touchegg.enable = false;
  
  # PowerTOP automatic tuning service
  # Disabled - conflicts with manual USB power management for sleep stability
  # systemd.services.powertop-autotune = {
  #   enable = true;
  #   description = "PowerTOP Auto Tune on Boot";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "/run/current-system/sw/bin/powertop --auto-tune";
  #   };
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "multi-user.target" ];
  # };
  
  # Sudoers rules for Bluetooth toggle (no password required)
  security.sudo.extraRules = [
    {
      users = [ "miguel" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/modprobe btusb";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/modprobe -r btusb";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart bluetooth";
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
        Enable = "Source Sink Media Socket";
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
    # Enable runtime power management for PCI devices (except USB controllers)
    ACTION=="add", SUBSYSTEM=="pci", ATTR{class}!="0x0c03*", ATTR{power/control}="auto"

    # Disable wakeup for USB-C ports to prevent spurious wake events
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="xhci_hcd", ATTR{power/wakeup}="disabled"

    # Disable USB-C ACPI wakeup (fixes ucsi_acpi errors waking system)
    ACTION=="add", KERNEL=="USBC000:00", ATTR{power/wakeup}="disabled"
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
